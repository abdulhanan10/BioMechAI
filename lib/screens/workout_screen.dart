import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../services/pose_detection_service.dart';
import '../services/exercise_recognition_service.dart';
import '../services/form_validation_service.dart';
import '../services/video_recording_service.dart';
import '../models/exercise_block.dart';
import '../models/rep_record.dart';
import '../utils/app_theme.dart';
import '../widgets/skeleton_painter.dart';
import '../widgets/form_score_ring.dart';
import '../widgets/stat_chip.dart';
import '../widgets/weight_input_sheet.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  CameraController? _cameraController;
  final PoseDetectionService _poseService = PoseDetectionService();
  late final ExerciseRecognitionService _recognitionService;
  late final FormValidationService _validationService;
  final RepCounterService _repCounter = RepCounterService();

  List<Pose> _poses = [];
  SkeletonMode _skeletonMode = SkeletonMode.detecting;

  bool _isDetectingNewExercise = true;
  double _currentWeight = 0.0;
  String _feedback = "Perform your first rep to begin...";

  // We'll keep track of the exercise block so we can update it
  ExerciseBlock? _currentExerciseBlock;

  bool _isFrontCamera = true;
  bool _isSwitchingCamera = false;

  @override
  void initState() {
    super.initState();
    _recognitionService = ExerciseRecognitionService(_poseService);
    
    // We get height from user
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _validationService = FormValidationService(_poseService, auth.currentUser?.heightCm ?? 175.0);

    _initCamera();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWeightSheet();
    });
  }

  void _showWeightSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeightInputSheet(
        onSubmit: (weight) {
          setState(() {
            _currentWeight = weight;
          });
          final provider = Provider.of<WorkoutProvider>(context, listen: false);
          if (!provider.isSessionActive) {
            provider.startSession();
            provider.videoService.startRecording(_cameraController!);
          }
        },
      ),
    );
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final targetDirection = _isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;
    final camera = cameras.firstWhere((c) => c.lensDirection == targetDirection, orElse: () => cameras.first);

    _cameraController = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream((image) async {
      final poses = await _poseService.processFrame(image, camera);
      if (poses.isNotEmpty) {
        _processPoses(poses.first);
        if (mounted) {
          setState(() {
            _poses = poses;
          });
        }
      }
    });
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || _cameraController == null) return;
    
    setState(() {
      _isSwitchingCamera = true;
    });

    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    bool wasRecording = _cameraController!.value.isRecordingVideo;
    
    if (wasRecording) {
      await provider.videoService.stopRecording();
    }

    if (_cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    
    await _cameraController!.dispose();
    _cameraController = null;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

    await _initCamera();
    
    if (wasRecording && _cameraController != null) {
      provider.videoService.startRecording(_cameraController!);
    }

    setState(() {
      _isSwitchingCamera = false;
    });
  }

  void _processPoses(Pose pose) {
    if (_isDetectingNewExercise) {
      _recognitionService.detectFirstRep(pose);
      if (_recognitionService.confirmedExercise != null) {
        _startExercise(_recognitionService.confirmedExercise!);
      }
    } else {
      if (_recognitionService.confirmedExercise != null) {
        // Validate form
        final result = _validationService.validate(pose, _recognitionService.confirmedExercise!);
        
        // Count rep
        double primaryAngle = _getPrimaryAngle(pose, _recognitionService.confirmedExercise!);
        bool repCompleted = _repCounter.update(primaryAngle, result.isValid, result.score);

        if (mounted) {
          setState(() {
            _skeletonMode = result.isValid ? SkeletonMode.valid : SkeletonMode.invalid;
            _feedback = result.feedback;
          });
        }

        if (repCompleted) {
          final rep = RepRecord(
            repNumber: _repCounter.totalReps,
            exerciseName: _recognitionService.confirmedExercise!,
            formScore: result.score,
            isValid: result.isValid,
            errorsDetected: result.errors,
            primaryAngle: primaryAngle,
            timestamp: DateTime.now(),
            weightUsed: _currentWeight,
          );
          Provider.of<WorkoutProvider>(context, listen: false).addRep(rep);
          _updateCurrentExerciseBlock();
        }

        // Check if stopped
        _recognitionService.detectExerciseChange(pose);
        if (_recognitionService.exerciseChangeDetected) {
          _endCurrentExercise();
        }
      }
    }
  }

  void _startExercise(String name) {
    setState(() {
      _isDetectingNewExercise = false;
      _skeletonMode = SkeletonMode.valid;
      _feedback = "Great $name form! 💪";
    });
    
    _repCounter.reset();
    
    _currentExerciseBlock = ExerciseBlock(
      exerciseName: name,
      muscleGroup: _getMuscleGroup(name),
      category: 'Strength',
      totalReps: 0,
      validReps: 0,
      avgFormScore: 100.0,
      weightUsed: _currentWeight,
      startTimestamp: DateTime.now(),
      endTimestamp: DateTime.now(),
    );
  }

  void _updateCurrentExerciseBlock() {
    if (_currentExerciseBlock != null) {
      _currentExerciseBlock!.totalReps = _repCounter.totalReps;
      _currentExerciseBlock!.validReps = _repCounter.validReps;
      _currentExerciseBlock!.avgFormScore = _repCounter.avgScore;
      _currentExerciseBlock!.endTimestamp = DateTime.now();
    }
  }

  void _endCurrentExercise() {
    if (_currentExerciseBlock != null && _currentExerciseBlock!.totalReps > 0) {
      Provider.of<WorkoutProvider>(context, listen: false).addExerciseBlock(_currentExerciseBlock!);
    }
    _currentExerciseBlock = null;
    _recognitionService.reset();
    
    if (mounted) {
      setState(() {
        _isDetectingNewExercise = true;
        _skeletonMode = SkeletonMode.detecting;
        _feedback = "New exercise? Starting detection...";
      });
      _showWeightSheet();
    }
  }

  Future<void> _endSession() async {
    _endCurrentExercise();
    final provider = Provider.of<WorkoutProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    String? videoPath = await provider.videoService.stopRecording();
    await provider.endSession(auth.currentUser!.uid, videoPath: videoPath);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  double _getPrimaryAngle(Pose pose, String exercise) {
    if (exercise == "Squat") {
      return _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftKnee],
        pose.landmarks[PoseLandmarkType.leftAnkle]
      ) ?? 180.0;
    }
    return 180.0;
  }

  String _getMuscleGroup(String name) {
    switch (name) {
      case 'Squat': return 'Legs';
      case 'Push-Up': return 'Chest';
      case 'Bicep Curl': return 'Arms';
      default: return 'Full Body';
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(backgroundColor: AppTheme.bg, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Camera
          CameraPreview(_cameraController!),

          // Layer 2: Skeleton
          CustomPaint(
            painter: SkeletonPainter(
              poses: _poses,
              imageSize: Size(_cameraController!.value.previewSize!.height, _cameraController!.value.previewSize!.width),
              isFront: _isFrontCamera,
              mode: _skeletonMode,
            ),
          ),

          // Layer 3: Top HUD
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.bg.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    _isDetectingNewExercise ? "Detecting..." : "${_recognitionService.confirmedExercise} (${(_recognitionService.confidence * 100).toInt()}%)",
                    style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
                      onPressed: _switchCamera,
                    ),
                    const SizedBox(width: 8),
                    FormScoreRing(score: _repCounter.avgScore, size: 50),
                  ],
                ),
              ],
            ),
          ),

          // Layer 4: Timer & REC indicator
          Positioned(
            top: 100,
            right: 16,
            child: Row(
              children: [
                if (provider.isSessionActive)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text('REC', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.red, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${(provider.elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(provider.elapsedSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Layer 5: Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.bg.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatChip(label: 'Valid Reps', value: '${_repCounter.validReps}', icon: Icons.check_circle, color: AppTheme.green),
                      StatChip(label: 'Total Reps', value: '${_repCounter.totalReps}', icon: Icons.repeat, color: AppTheme.blue),
                      StatChip(label: 'Weight', value: '$_currentWeight kg', icon: Icons.fitness_center, color: AppTheme.purple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _skeletonMode == SkeletonMode.invalid ? AppTheme.red.withOpacity(0.2) : AppTheme.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _feedback,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _skeletonMode == SkeletonMode.invalid ? AppTheme.red : AppTheme.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: provider.isUploading ? null : _endSession,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
                      child: provider.isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('End Session', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

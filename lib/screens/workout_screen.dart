import 'dart:async';
import 'dart:io';
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
        onSubmit: (weight) async {
          setState(() {
            _currentWeight = weight;
          });
          final provider = Provider.of<WorkoutProvider>(context, listen: false);
          if (!provider.isSessionActive) {
            provider.startSession();
            if (!_cameraController!.value.isStreamingImages) {
              final cameras = await availableCameras();
              final targetDirection = _isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;
              final camera = cameras.firstWhere((c) => c.lensDirection == targetDirection, orElse: () => cameras.first);
              _cameraController!.startImageStream((image) => _handleCameraImage(image, camera));
            }
          }
        },
      ),
    );
  }

  Future<void> _handleCameraImage(CameraImage image, CameraDescription camera) async {
    final poses = await _poseService.processFrame(image, camera);
    if (poses.isNotEmpty) {
      final Size imageSize = (camera.sensorOrientation == 90 || camera.sensorOrientation == 270)
          ? Size(image.height.toDouble(), image.width.toDouble())
          : Size(image.width.toDouble(), image.height.toDouble());
          
      _processPoses(poses.first, imageSize);
      if (mounted) {
        setState(() {
          _poses = poses;
        });
      }
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final targetDirection = _isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;
    final camera = cameras.firstWhere((c) => c.lensDirection == targetDirection, orElse: () => cameras.first);

    _cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream((image) => _handleCameraImage(image, camera));
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || _cameraController == null) return;
    
    setState(() {
      _isSwitchingCamera = true;
    });

    if (_cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    
    await _cameraController!.dispose();
    _cameraController = null;

    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });

    await _initCamera();

    setState(() {
      _isSwitchingCamera = false;
    });
  }

  void _processPoses(Pose pose, Size imageSize) {
    if (_isDetectingNewExercise) {
      _recognitionService.detectFirstRep(pose, imageSize);
      if (_recognitionService.confirmedExercise != null) {
        _startExercise(_recognitionService.confirmedExercise!);
      }
    } else {
      if (_recognitionService.confirmedExercise != null) {
        // Validate form
        final result = _validationService.validate(pose, _recognitionService.confirmedExercise!);
        
        // Count rep
        double primaryAngle = _getPrimaryAngle(pose, _recognitionService.confirmedExercise!);
        bool repCompleted = _repCounter.update(primaryAngle, result.isValid, result.score, _recognitionService.confirmedExercise!);

        if (_recognitionService.confirmedExercise == "Plank" && _currentExerciseBlock != null) {
           int secondsHeld = DateTime.now().difference(_currentExerciseBlock!.startTimestamp).inSeconds;
           if (secondsHeld > _repCounter.totalReps) {
              _repCounter.totalReps = secondsHeld;
              if (result.isValid) _repCounter.validReps = secondsHeld;
              _repCounter.avgScore = ((_repCounter.avgScore * (secondsHeld - 1)) + result.score) / max(1, secondsHeld);
              _updateCurrentExerciseBlock();
           }
        }

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
    if (_currentExerciseBlock != null && (_currentExerciseBlock!.totalReps > 0 || _currentExerciseBlock!.exerciseName == "Plank")) {
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
    await provider.endSession(auth.currentUser!.uid);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  double _getPrimaryAngle(Pose pose, String exercise) {
    if (exercise == "Squat" || exercise == "Lunge" || exercise == "High Knees") {
      return _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftKnee],
        pose.landmarks[PoseLandmarkType.leftAnkle]
      ) ?? 180.0;
    } else if (exercise == "Push-Up" || exercise == "Bicep Curl") {
      return _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftShoulder],
        pose.landmarks[PoseLandmarkType.leftElbow],
        pose.landmarks[PoseLandmarkType.leftWrist]
      ) ?? 180.0;
    } else if (exercise == "Jumping Jack") {
      return _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftShoulder],
        pose.landmarks[PoseLandmarkType.leftWrist]
      ) ?? 180.0;
    } else if (exercise == "Plank") {
      return _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftShoulder],
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftAnkle]
      ) ?? 180.0;
    }
    return 180.0;
  }

  String _getMuscleGroup(String name) {
    switch (name) {
      case 'Squat': 
      case 'Lunge': return 'Legs';
      case 'Push-Up': return 'Chest';
      case 'Bicep Curl': return 'Arms';
      case 'Plank': return 'Core';
      case 'Jumping Jack':
      case 'High Knees': return 'Cardio';
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
          // Layer 1 & 2: Camera and Skeleton
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
              if (scale < 1) scale = 1 / scale;
              return Transform.scale(
                scale: scale,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1 / _cameraController!.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController!),
                        CustomPaint(
                          painter: SkeletonPainter(
                            poses: _poses,
                            imageSize: Size(_cameraController!.value.previewSize!.height, _cameraController!.value.previewSize!.width),
                            isFront: _isFrontCamera,
                            mode: _skeletonMode,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
                    _isDetectingNewExercise ? "Detecting..." : "${_recognitionService.confirmedExercise}",
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

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:ui';
import '../models/exercise_block.dart';
import 'pose_detection_service.dart';

class ExerciseRecognitionService {
  final PoseDetectionService _poseService;

  // Change this to your local IP address (e.g., 'http://192.168.1.5:5000/classify')
  // For Android Emulator, use 'http://10.0.2.2:5000/classify'
  // For testing the deployed app, use 'https://biomechai.onrender.com/classify'
  static const String apiUrl = 'https://biomechai.onrender.com/classify';

  String? confirmedExercise;
  double confidence = 0.0;
  bool isApiOffline = false;
  
  bool exerciseChangeDetected = false;
  List<ExerciseBlock> exerciseTimeline = [];

  // For detectFirstRep
  double? _initialKneeAngle;
  double? _initialElbowAngle;
  bool _firstRepDetected = false;

  // For detectExerciseChange
  DateTime? _lastMovementTime;

  ExerciseRecognitionService(this._poseService);

  List<List<List<double>>> collectLandmarks(Size imageSize) {
    final buffer = _poseService.landmarkBuffer.toList();
    List<List<List<double>>> result = [];

    for (var poses in buffer) {
      if (poses.isEmpty) {
        // Pad with zeros if no pose
        result.add(List.generate(33, (_) => [0.0, 0.0, 0.0]));
        continue;
      }
      var pose = poses.first;
      List<List<double>> frameData = [];
      
      // MLKit Pose landmarks are indexed 0-32
      for (int i = 0; i <= 32; i++) {
        var lmType = PoseLandmarkType.values.firstWhere((e) => e.index == i, orElse: () => PoseLandmarkType.nose);
        var lm = pose.landmarks[lmType];
        if (lm != null) {
          // Normalize exact coordinates by width and height to match MediaPipe
          frameData.add([lm.x / imageSize.width, lm.y / imageSize.height, lm.z / imageSize.width]); 
        } else {
          frameData.add([0.0, 0.0, 0.0]);
        }
      }
      result.add(frameData);
    }
    
    // Pad to 90 if less
    while (result.length < 90) {
      result.add(List.generate(33, (_) => [0.0, 0.0, 0.0]));
    }
    
    return result;
  }

  void detectFirstRep(Pose pose, Size imageSize) {
    if (_firstRepDetected) return;

    _updateMovementTime(pose);

    // Trigger classification once we have collected at least 45 frames (approx 1.5 seconds)
    // This allows the custom model to identify ANY exercise, not just squats/pushups.
    if (_poseService.landmarkBuffer.length >= 45) {
      _firstRepDetected = true;
      _triggerClassification("Custom Exercise", imageSize);
    }
  }

  void _triggerClassification(String heuristicFallback, Size imageSize) async {
    final landmarks = collectLandmarks(imageSize);
    await sendToAPI(landmarks, heuristicFallback);
  }

  Future<void> sendToAPI(List<List<List<double>>> landmarks, String heuristicFallback) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'landmarks': landmarks,
          'fps': 30
        }),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double score = (data['confidence'] ?? 0).toDouble();
        if (score >= 0.85) {
          confirmedExercise = data['exercise'];
          confidence = score;
          isApiOffline = false;
        } else {
          _useFallbackDetection(heuristicFallback);
        }
      } else {
        _useFallbackDetection(heuristicFallback);
      }
    } catch (e) {
      _useFallbackDetection(heuristicFallback);
    }
  }

  void _useFallbackDetection(String heuristicFallback) {
    isApiOffline = true;
    confirmedExercise = heuristicFallback;
    confidence = 0.85;
  }

  void detectExerciseChange(Pose pose) {
    _updateMovementTime(pose);

    if (_lastMovementTime != null) {
      final diff = DateTime.now().difference(_lastMovementTime!).inSeconds;
      if (diff >= 5) {
        exerciseChangeDetected = true;
        _poseService.landmarkBuffer.clear();
        _firstRepDetected = false;
        _initialKneeAngle = null;
        _initialElbowAngle = null;
        confirmedExercise = null;
        _lastMovementTime = DateTime.now(); // reset
      }
    }
  }

  void _updateMovementTime(Pose pose) {
    // Check if nose is moving to update movement time
    var nose = pose.landmarks[PoseLandmarkType.nose];
    if (nose != null) {
       // In a real app we would check delta from previous frame.
       // For now, assume any frame means they are tracking.
       // If difference is small, we consider it stationary.
       // Without previous pose tracked, we'll just simplify:
       _lastMovementTime = DateTime.now();
    }
  }

  void reset() {
    exerciseTimeline.clear();
    _poseService.landmarkBuffer.clear();
    confirmedExercise = null;
    confidence = 0.0;
    exerciseChangeDetected = false;
    _firstRepDetected = false;
    _initialKneeAngle = null;
    _initialElbowAngle = null;
    _lastMovementTime = null;
  }
}

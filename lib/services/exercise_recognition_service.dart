import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

    // Trigger classification once we have collected at least 90 frames (approx 3 seconds)
    // We use a robust local heuristic first to avoid backend misclassifications.
    if (_poseService.landmarkBuffer.length >= 90) {
      _firstRepDetected = true;
      String localGuess = _runLocalHeuristics();
      if (localGuess != "Unknown") {
        confirmedExercise = localGuess;
        confidence = 0.99; // Highly confident locally
        isApiOffline = false;
        return;
      }
      _triggerClassification("Custom Exercise", imageSize);
    }
  }

  String _runLocalHeuristics() {
    if (_poseService.landmarkBuffer.isEmpty) return "Unknown";
    
    double minLeftKnee = 180, maxLeftKnee = 0;
    double minRightKnee = 180, maxRightKnee = 0;
    double minLeftElbow = 180, maxLeftElbow = 0;
    double minRightElbow = 180, maxRightElbow = 0;
    double minLeftHip = 180, maxLeftHip = 0;
    double minRightHip = 180, maxRightHip = 0;
    double minWristY = 10000, maxWristY = 0;
    double noseY = 0;
    bool isHorizontal = false;
    bool bothHipsFlexed = false;
    bool bothKneesFlexed = false;
    bool oneHipFlexedOneExtended = false;
    bool oneKneeFlexedOneExtended = false;

    for (var poses in _poseService.landmarkBuffer) {
      if (poses.isEmpty) continue;
      var pose = poses.first;
      
      double? lk = _poseService.jointAngle(pose.landmarks[PoseLandmarkType.leftHip], pose.landmarks[PoseLandmarkType.leftKnee], pose.landmarks[PoseLandmarkType.leftAnkle]);
      if (lk != null) { minLeftKnee = min(minLeftKnee, lk); maxLeftKnee = max(maxLeftKnee, lk); }
      
      double? rk = _poseService.jointAngle(pose.landmarks[PoseLandmarkType.rightHip], pose.landmarks[PoseLandmarkType.rightKnee], pose.landmarks[PoseLandmarkType.rightAnkle]);
      if (rk != null) { minRightKnee = min(minRightKnee, rk); maxRightKnee = max(maxRightKnee, rk); }
      
      double? le = _poseService.jointAngle(pose.landmarks[PoseLandmarkType.leftShoulder], pose.landmarks[PoseLandmarkType.leftElbow], pose.landmarks[PoseLandmarkType.leftWrist]);
      if (le != null) { minLeftElbow = min(minLeftElbow, le); maxLeftElbow = max(maxLeftElbow, le); }
      
      double? re = _poseService.jointAngle(pose.landmarks[PoseLandmarkType.rightShoulder], pose.landmarks[PoseLandmarkType.rightElbow], pose.landmarks[PoseLandmarkType.rightWrist]);
      if (re != null) { minRightElbow = min(minRightElbow, re); maxRightElbow = max(maxRightElbow, re); }

      double? lh = _poseService.jointAngle(pose.landmarks[PoseLandmarkType.leftShoulder], pose.landmarks[PoseLandmarkType.leftHip], pose.landmarks[PoseLandmarkType.leftKnee]);
      if (lh != null) { minLeftHip = min(minLeftHip, lh); maxLeftHip = max(maxLeftHip, lh); }
      
      double? rh = _poseService.jointAngle(pose.landmarks[PoseLandmarkType.rightShoulder], pose.landmarks[PoseLandmarkType.rightHip], pose.landmarks[PoseLandmarkType.rightKnee]);
      if (rh != null) { minRightHip = min(minRightHip, rh); maxRightHip = max(maxRightHip, rh); }

      // Track simultaneous flexion for legs to distinguish Squat/Lunge/HighKnees
      if (lk != null && rk != null && lh != null && rh != null) {
          if (lh < 130 && rh < 130) bothHipsFlexed = true;
          if (lk < 130 && rk < 130) bothKneesFlexed = true;
          if ((lh < 120 && rh > 150) || (rh < 120 && lh > 150)) oneHipFlexedOneExtended = true;
          if ((lk < 120 && rk > 150) || (rk < 120 && lk > 150)) oneKneeFlexedOneExtended = true;
      }

      var lw = pose.landmarks[PoseLandmarkType.leftWrist];
      var rw = pose.landmarks[PoseLandmarkType.rightWrist];
      if (lw != null) { minWristY = min(minWristY, lw.y); maxWristY = max(maxWristY, lw.y); }
      if (rw != null) { minWristY = min(minWristY, rw.y); maxWristY = max(maxWristY, rw.y); }
      
      var n = pose.landmarks[PoseLandmarkType.nose];
      if (n != null) noseY = n.y;

      var s = pose.landmarks[PoseLandmarkType.leftShoulder];
      var a = pose.landmarks[PoseLandmarkType.leftAnkle];
      if (s != null && a != null) {
          if ((a.y - s.y).abs() < (a.x - s.x).abs() * 1.5) {
             isHorizontal = true;
          }
      }
    }

    double leftKneeRom = maxLeftKnee - minLeftKnee;
    double rightKneeRom = maxRightKnee - minRightKnee;
    double leftElbowRom = maxLeftElbow - minLeftElbow;
    double rightElbowRom = maxRightElbow - minRightElbow;
    double leftHipRom = maxLeftHip - minLeftHip;
    double rightHipRom = maxRightHip - minRightHip;

    if (isHorizontal) {
      if (leftElbowRom > 30 || rightElbowRom > 30) return "Push-Up";
      return "Plank";
    }

    if (minWristY < noseY && (maxWristY - minWristY) > 200) {
      return "Jumping Jack";
    }

    if (leftElbowRom > 40 || rightElbowRom > 40) {
      if (leftKneeRom < 25 && rightKneeRom < 25) return "Bicep Curl";
    }

    if (leftKneeRom > 25 || rightKneeRom > 25 || leftHipRom > 25 || rightHipRom > 25) {
      if (bothHipsFlexed && bothKneesFlexed) {
         return "Squat";
      }
      
      if (oneHipFlexedOneExtended) {
         if (bothKneesFlexed) {
             return "Lunge";
         }
         if (oneKneeFlexedOneExtended || minLeftHip < 110 || minRightHip < 110) {
             return "High Knees";
         }
      }

      // Fallbacks
      if (bothKneesFlexed && (minLeftKnee - minRightKnee).abs() < 30) return "Squat";
      if (minLeftHip < 110 || minRightHip < 110) return "High Knees";
    }

    return "Unknown";
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
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double score = (data['confidence'] ?? 0).toDouble();
        if (score >= 0.85) {
          confirmedExercise = data['exercise'];
          confidence = score;
          isApiOffline = false;
        } else {
          // If low confidence, clear buffer and allow retry instead of locking in
          _poseService.landmarkBuffer.clear();
          _firstRepDetected = false;
        }
      } else {
        // If server error, clear buffer to allow retry
        _poseService.landmarkBuffer.clear();
        _firstRepDetected = false;
      }
    } catch (e) {
      // If timeout or network error, clear buffer to allow retry
      _poseService.landmarkBuffer.clear();
      _firstRepDetected = false;
    }
  }

  void pingAPI() {
    try {
      http.get(Uri.parse(apiUrl.replaceAll('/classify', '/health'))).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('', 500));
    } catch (e) {
      // ignore
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
    pingAPI(); // Wake up Render
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

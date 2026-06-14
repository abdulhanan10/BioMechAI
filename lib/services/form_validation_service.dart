import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'pose_detection_service.dart';

class FormResult {
  final double score;
  final bool isValid;
  final List<String> errors;
  final String feedback;

  FormResult({
    required this.score,
    required this.isValid,
    required this.errors,
    required this.feedback,
  });
}

class FormValidationService {
  final PoseDetectionService _poseService;
  final double heightCm;
  late final double heightAdj;

  final List<double> _angleHistory = [];

  FormValidationService(this._poseService, this.heightCm) {
    heightAdj = (heightCm - 175) / 175 * 10.0;
  }

  FormResult validate(Pose pose, String exercise) {
    double score = 100.0;
    List<String> errors = [];
    bool hasHighSeverity = false;

    // Pattern 1: Safety Limits
    _checkSafetyLimits(pose, exercise, errors, () {
      score -= 36;
      hasHighSeverity = true;
    });

    // Pattern 2: Smoothness
    double primaryAngle = _getPrimaryAngle(pose, exercise);
    _angleHistory.add(primaryAngle);
    if (_angleHistory.length > 8) {
      _angleHistory.removeAt(0);
    }
    
    if (_angleHistory.length == 8) {
      double mean = _angleHistory.reduce((a, b) => a + b) / 8;
      double variance = _angleHistory.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / 8;
      double std = sqrt(variance);
      score = min(score, max(0, 100 - std * 3.2));
    }

    // Pattern 3: Symmetry
    _checkSymmetry(pose, errors, () {
      score -= 8;
    });

    // Final score clamping
    score = score.clamp(0.0, 100.0);
    bool isValid = score >= 60 && !hasHighSeverity;

    String feedback = "";
    if (score >= 86) {
      feedback = "Great $exercise form! 💪";
    } else if (score >= 72) {
      feedback = errors.isNotEmpty ? errors.first : "Good form";
    } else {
      feedback = errors.isNotEmpty ? "Fix: ${errors.first}" : "Improve form";
    }

    return FormResult(
      score: score,
      isValid: isValid,
      errors: errors,
      feedback: feedback,
    );
  }

  void _checkSafetyLimits(Pose pose, String exercise, List<String> errors, Function onHighSeverity) {
    // Basic mock of safety limits
    if (exercise == "Squat") {
      double? kneeAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftKnee],
        pose.landmarks[PoseLandmarkType.leftAnkle]
      );
      if (kneeAngle != null && (kneeAngle < 58 || kneeAngle > 180)) {
        errors.add("Knee angle out of safety range");
        onHighSeverity();
      }
    }
    // Implement other exercises per requirements
  }

  void _checkSymmetry(Pose pose, List<String> errors, Function onLowSeverity) {
    var ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    var rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (ls != null && rs != null) {
      if ((ls.y - rs.y).abs() > 0.20 * 1000) { // Rough heuristic if using raw coords
        errors.add("Shoulders are not symmetric");
        onLowSeverity();
      }
    }
  }

  double _getPrimaryAngle(Pose pose, String exercise) {
    if (exercise == "Squat" || exercise == "Lunge" || exercise == "High Knees") {
      double leftAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftKnee],
        pose.landmarks[PoseLandmarkType.leftAnkle]
      ) ?? 180.0;
      double rightAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.rightHip],
        pose.landmarks[PoseLandmarkType.rightKnee],
        pose.landmarks[PoseLandmarkType.rightAnkle]
      ) ?? 180.0;
      return min(leftAngle, rightAngle);
    } else if (exercise == "Push-Up" || exercise == "Bicep Curl") {
      double leftAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftShoulder],
        pose.landmarks[PoseLandmarkType.leftElbow],
        pose.landmarks[PoseLandmarkType.leftWrist]
      ) ?? 180.0;
      double rightAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.rightShoulder],
        pose.landmarks[PoseLandmarkType.rightElbow],
        pose.landmarks[PoseLandmarkType.rightWrist]
      ) ?? 180.0;
      return min(leftAngle, rightAngle);
    } else if (exercise == "Jumping Jack") {
      double leftAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftShoulder],
        pose.landmarks[PoseLandmarkType.leftWrist]
      ) ?? 180.0;
      double rightAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.rightHip],
        pose.landmarks[PoseLandmarkType.rightShoulder],
        pose.landmarks[PoseLandmarkType.rightWrist]
      ) ?? 180.0;
      return max(leftAngle, rightAngle);
    } else if (exercise == "Plank") {
      double leftAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.leftShoulder],
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.leftAnkle]
      ) ?? 180.0;
      double rightAngle = _poseService.jointAngle(
        pose.landmarks[PoseLandmarkType.rightShoulder],
        pose.landmarks[PoseLandmarkType.rightHip],
        pose.landmarks[PoseLandmarkType.rightAnkle]
      ) ?? 180.0;
      return min(leftAngle, rightAngle);
    }
    return 180.0;
  }
}

class RepCounterService {
  String _state = 'up';
  int totalReps = 0;
  int validReps = 0;
  double avgScore = 0;
  List<dynamic> repHistory = [];

  bool update(double angle, bool isValid, double score, String exercise) {
    bool repCompleted = false;
    
    // Strict rep counting thresholds tailored to exercise to prevent fake reps
    double downThresh = 110; // Must go deep enough to count as a rep
    double upThresh = 160;   // Must stand back up
    
    if (exercise == 'Jumping Jack') {
        downThresh = 60; // Arms must go down below T-pose
        upThresh = 130;  // Arms must go up above T-pose
    } else if (exercise == 'Push-Up' || exercise == 'Bicep Curl') {
        downThresh = 100; // Must bend elbows to at least 100 degrees
        upThresh = 150;   // Must straighten arms
    } else if (exercise == 'Plank') {
        return false; // Planks are held, not counted in reps
    }
    
    if (_state == 'up' && angle < downThresh) {
      _state = 'down';
    } else if (_state == 'down' && angle > upThresh) {
      _state = 'up';
      repCompleted = true;
      totalReps++;
      if (isValid) validReps++;
      
      // Update running average
      avgScore = ((avgScore * (totalReps - 1)) + score) / totalReps;
    }
    return repCompleted;
  }

  void reset() {
    _state = 'up';
    totalReps = 0;
    validReps = 0;
    avgScore = 0;
    repHistory.clear();
  }
}

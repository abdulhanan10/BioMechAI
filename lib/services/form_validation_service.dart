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

    void deduct(double amount, String errorMsg, {bool highSeverity = false}) {
      score -= amount;
      if (!errors.contains(errorMsg)) errors.add(errorMsg);
      if (highSeverity) hasHighSeverity = true;
    }

    // Unique accuracy rules per exercise
    switch (exercise) {
      case "Squat":
        double? leftKnee = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.leftHip],
            pose.landmarks[PoseLandmarkType.leftKnee],
            pose.landmarks[PoseLandmarkType.leftAnkle]);
        if (leftKnee != null && (leftKnee < 45 || leftKnee > 180)) {
          deduct(20, "Knee angle unsafe", highSeverity: true);
        }
        _checkSymmetry(pose, errors, () => deduct(10, "Shoulders uneven"));
        break;

      case "Lunge":
        double? leftKnee = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.leftHip],
            pose.landmarks[PoseLandmarkType.leftKnee],
            pose.landmarks[PoseLandmarkType.leftAnkle]);
        double? rightKnee = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.rightHip],
            pose.landmarks[PoseLandmarkType.rightKnee],
            pose.landmarks[PoseLandmarkType.rightAnkle]);
        double minKnee = min(leftKnee ?? 180, rightKnee ?? 180);
        if (minKnee < 50) {
          deduct(15, "Don't overextend knee");
        }
        double? backAngle = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.leftShoulder],
            pose.landmarks[PoseLandmarkType.leftHip],
            pose.landmarks[PoseLandmarkType.leftKnee]);
        if (backAngle != null && backAngle < 130) {
          deduct(15, "Keep torso upright");
        }
        break;

      case "High Knees":
        double? leftHip = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.leftShoulder],
            pose.landmarks[PoseLandmarkType.leftHip],
            pose.landmarks[PoseLandmarkType.leftKnee]);
        double? rightHip = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.rightShoulder],
            pose.landmarks[PoseLandmarkType.rightHip],
            pose.landmarks[PoseLandmarkType.rightKnee]);
        double minHip = min(leftHip ?? 180, rightHip ?? 180);
        if (minHip > 130) {
           deduct(10, "Lift knees higher");
        }
        break;

      case "Push-Up":
        double? bodyAlignment = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.leftShoulder],
            pose.landmarks[PoseLandmarkType.leftHip],
            pose.landmarks[PoseLandmarkType.leftAnkle]);
        if (bodyAlignment != null && (bodyAlignment < 140 || bodyAlignment > 220)) {
          deduct(25, "Keep body straight", highSeverity: true);
        }
        break;

      case "Bicep Curl":
        double? bodySway = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.leftShoulder],
            pose.landmarks[PoseLandmarkType.leftHip],
            pose.landmarks[PoseLandmarkType.leftAnkle]);
        if (bodySway != null && bodySway < 155) {
          deduct(15, "Don't swing back");
        }
        break;

      case "Jumping Jack":
        var lw = pose.landmarks[PoseLandmarkType.leftWrist];
        var rw = pose.landmarks[PoseLandmarkType.rightWrist];
        if (lw != null && rw != null) {
          if ((lw.y - rw.y).abs() > 0.30 * 1000) {
            deduct(10, "Move arms together");
          }
        }
        break;

      case "Plank":
        double? plankAlignment = _poseService.jointAngle(
            pose.landmarks[PoseLandmarkType.leftShoulder],
            pose.landmarks[PoseLandmarkType.leftHip],
            pose.landmarks[PoseLandmarkType.leftAnkle]);
        if (plankAlignment != null) {
          if (plankAlignment < 150) {
            deduct(25, "Don't let hips sag", highSeverity: true);
          } else if (plankAlignment > 190) {
            deduct(15, "Lower your hips");
          }
        }
        break;
    }

    // Smoothness (Less strict penalty)
    double primaryAngle = _getPrimaryAngle(pose, exercise);
    _angleHistory.add(primaryAngle);
    if (_angleHistory.length > 8) {
      _angleHistory.removeAt(0);
    }
    
    if (_angleHistory.length == 8) {
      double mean = _angleHistory.reduce((a, b) => a + b) / 8;
      double variance = _angleHistory.map((a) => pow(a - mean, 2)).reduce((a, b) => a + b) / 8;
      double std = sqrt(variance);
      score -= std * 1.2; // Much less strict than 3.2
    }

    // Final score clamping
    score = score.clamp(0.0, 100.0);
    
    // Normal threshold for valid rep (was 60, now 45)
    bool isValid = score >= 45 && !hasHighSeverity;

    String feedback = "";
    if (score >= 80) {
      feedback = "Great $exercise form! 💪";
    } else if (score >= 45) {
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
    double downThresh = 120; // Relaxed: Must go deep enough to count as a rep
    double upThresh = 150;   // Relaxed: Must stand back up
    
    if (exercise == 'Jumping Jack') {
        downThresh = 75; // Relaxed: Arms must go down
        upThresh = 120;  // Relaxed: Arms must go up
    } else if (exercise == 'Push-Up' || exercise == 'Bicep Curl') {
        downThresh = 110; // Relaxed: Bend elbows to 110 degrees
        upThresh = 140;   // Relaxed: Straighten arms
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

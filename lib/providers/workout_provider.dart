import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_session_model.dart';
import '../models/exercise_block.dart';
import '../models/rep_record.dart';
import '../services/firebase_service.dart';
import '../services/video_recording_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final VideoRecordingService videoService = VideoRecordingService();
  final Uuid _uuid = const Uuid();

  bool isSessionActive = false;
  int elapsedSeconds = 0;
  Timer? _timer;
  
  String? currentSessionId;
  DateTime? sessionStartTime;

  List<ExerciseBlock> exerciseTimeline = [];
  List<RepRecord> currentExerciseReps = [];

  bool isUploading = false;

  void startSession() {
    isSessionActive = true;
    elapsedSeconds = 0;
    currentSessionId = _uuid.v4();
    sessionStartTime = DateTime.now();
    exerciseTimeline.clear();
    currentExerciseReps.clear();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds++;
      notifyListeners();
    });
    
    notifyListeners();
  }

  void addExerciseBlock(ExerciseBlock block) {
    exerciseTimeline.add(block);
    notifyListeners();
  }

  void addRep(RepRecord rep) {
    currentExerciseReps.add(rep);
    notifyListeners();
  }

  void clearCurrentReps() {
    currentExerciseReps.clear();
    notifyListeners();
  }

  Future<void> endSession(String userId, {String? videoPath}) async {
    if (!isSessionActive) return;
    
    _timer?.cancel();
    isSessionActive = false;
    isUploading = true;
    notifyListeners();

    String? videoUrl;
    if (videoPath != null && currentSessionId != null) {
      videoUrl = await videoService.uploadToFirebase(videoPath, currentSessionId!, userId);
    }

    if (currentSessionId != null && sessionStartTime != null) {
      int totalValidReps = 0;
      int totalReps = 0;
      double totalScore = 0;

      for (var block in exerciseTimeline) {
        totalValidReps += block.validReps;
        totalReps += block.totalReps;
        totalScore += block.avgFormScore * block.totalReps; // weighted average prep
      }

      double avgFormScore = totalReps > 0 ? totalScore / totalReps : 0;
      DateTime now = DateTime.now();

      SessionModel session = SessionModel(
        sessionId: currentSessionId!,
        userId: userId,
        startTime: sessionStartTime!,
        endTime: now,
        totalDuration: elapsedSeconds,
        avgFormScore: avgFormScore,
        totalValidReps: totalValidReps,
        totalReps: totalReps,
        videoUrl: videoUrl,
        sessionDate: now,
        dayOfWeek: _getDayOfWeek(now),
        exerciseCount: exerciseTimeline.length,
      );

      await _firebaseService.saveWorkoutSession(session);

      for (var block in exerciseTimeline) {
        await _firebaseService.saveExerciseBlock(userId, currentSessionId!, block);
      }

      for (var rep in currentExerciseReps) {
        await _firebaseService.saveRepRecord(userId, currentSessionId!, rep);
      }
    }

    isUploading = false;
    currentSessionId = null;
    sessionStartTime = null;
    elapsedSeconds = 0;
    exerciseTimeline.clear();
    currentExerciseReps.clear();
    notifyListeners();
  }

  String _getDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int totalDuration; // in seconds
  final double avgFormScore;
  final int totalValidReps;
  final int totalReps;
  final String? videoUrl;
  final DateTime sessionDate;
  final String dayOfWeek;
  final int exerciseCount;
  final List<String> exerciseNames;
  final String? trainerFeedback;

  SessionModel({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
    required this.avgFormScore,
    required this.totalValidReps,
    required this.totalReps,
    this.videoUrl,
    required this.sessionDate,
    required this.dayOfWeek,
    required this.exerciseCount,
    this.exerciseNames = const [],
    this.trainerFeedback,
  });

  factory SessionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SessionModel(
      sessionId: documentId,
      userId: data['userId'] ?? '',
      startTime: data['startTime'] != null ? (data['startTime'] as Timestamp).toDate() : DateTime.now(),
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : DateTime.now(),
      totalDuration: data['totalDuration'] ?? 0,
      avgFormScore: (data['avgFormScore'] ?? 0).toDouble(),
      totalValidReps: data['totalValidReps'] ?? 0,
      totalReps: data['totalReps'] ?? 0,
      videoUrl: data['videoUrl'],
      sessionDate: data['sessionDate'] != null ? (data['sessionDate'] as Timestamp).toDate() : DateTime.now(),
      dayOfWeek: data['dayOfWeek'] ?? '',
      exerciseCount: data['exerciseCount'] ?? 0,
      exerciseNames: List<String>.from(data['exerciseNames'] ?? []),
      trainerFeedback: data['trainerFeedback'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalDuration': totalDuration,
      'avgFormScore': avgFormScore,
      'totalValidReps': totalValidReps,
      'totalReps': totalReps,
      'videoUrl': videoUrl,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'dayOfWeek': dayOfWeek,
      'exerciseCount': exerciseCount,
      'exerciseNames': exerciseNames,
      if (trainerFeedback != null) 'trainerFeedback': trainerFeedback,
    };
  }
}

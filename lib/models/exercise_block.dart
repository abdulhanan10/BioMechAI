import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseBlock {
  final String? id; 
  final String exerciseName;
  final String muscleGroup;
  final String category;
  int totalReps;
  int validReps;
  double avgFormScore;
  double weightUsed; 
  final DateTime startTimestamp;
  DateTime endTimestamp;

  ExerciseBlock({
    this.id,
    required this.exerciseName,
    required this.muscleGroup,
    required this.category,
    required this.totalReps,
    required this.validReps,
    required this.avgFormScore,
    required this.weightUsed,
    required this.startTimestamp,
    required this.endTimestamp,
  });

  factory ExerciseBlock.fromMap(Map<String, dynamic> data, String documentId) {
    return ExerciseBlock(
      id: documentId,
      exerciseName: data['exerciseName'] ?? '',
      muscleGroup: data['muscleGroup'] ?? '',
      category: data['category'] ?? '',
      totalReps: data['totalReps'] ?? 0,
      validReps: data['validReps'] ?? 0,
      avgFormScore: (data['avgFormScore'] ?? 0).toDouble(),
      weightUsed: (data['weightUsed'] ?? 0).toDouble(),
      startTimestamp: data['startTimestamp'] != null ? (data['startTimestamp'] as Timestamp).toDate() : DateTime.now(),
      endTimestamp: data['endTimestamp'] != null ? (data['endTimestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'category': category,
      'totalReps': totalReps,
      'validReps': validReps,
      'avgFormScore': avgFormScore,
      'weightUsed': weightUsed,
      'startTimestamp': Timestamp.fromDate(startTimestamp),
      'endTimestamp': Timestamp.fromDate(endTimestamp),
    };
  }
}

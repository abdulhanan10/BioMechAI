import 'package:cloud_firestore/cloud_firestore.dart';

class Recommendation {
  final String userId;
  final List<String> exercises;
  final String basedOn;
  final DateTime generatedAt;
  final bool approvedByTrainer;

  Recommendation({
    required this.userId,
    required this.exercises,
    required this.basedOn,
    required this.generatedAt,
    required this.approvedByTrainer,
  });

  factory Recommendation.fromMap(Map<String, dynamic> data, String documentId) {
    return Recommendation(
      userId: documentId,
      exercises: List<String>.from(data['exercises'] ?? []),
      basedOn: data['basedOn'] ?? '',
      generatedAt: data['generatedAt'] != null ? (data['generatedAt'] as Timestamp).toDate() : DateTime.now(),
      approvedByTrainer: data['approvedByTrainer'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exercises': exercises,
      'basedOn': basedOn,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'approvedByTrainer': approvedByTrainer,
    };
  }
}

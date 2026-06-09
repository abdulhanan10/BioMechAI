import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerFeedback {
  final String? id;
  final String trainerId;
  final String clientId;
  final String sessionId;
  final String feedbackText;
  final int videoTimestamp; // seconds
  final DateTime createdAt;

  TrainerFeedback({
    this.id,
    required this.trainerId,
    required this.clientId,
    required this.sessionId,
    required this.feedbackText,
    required this.videoTimestamp,
    required this.createdAt,
  });

  factory TrainerFeedback.fromMap(Map<String, dynamic> data, String documentId) {
    return TrainerFeedback(
      id: documentId,
      trainerId: data['trainerId'] ?? '',
      clientId: data['clientId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      feedbackText: data['feedbackText'] ?? '',
      videoTimestamp: data['videoTimestamp'] ?? 0,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trainerId': trainerId,
      'clientId': clientId,
      'sessionId': sessionId,
      'feedbackText': feedbackText,
      'videoTimestamp': videoTimestamp,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

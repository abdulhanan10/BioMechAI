import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerClient {
  final String id;
  final String trainerId;
  final String clientId;
  final DateTime linkedAt;

  TrainerClient({
    required this.id,
    required this.trainerId,
    required this.clientId,
    required this.linkedAt,
  });

  factory TrainerClient.fromMap(Map<String, dynamic> data, String documentId) {
    return TrainerClient(
      id: documentId,
      trainerId: data['trainerId'] ?? '',
      clientId: data['clientId'] ?? '',
      linkedAt: data['linkedAt'] != null ? (data['linkedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trainerId': trainerId,
      'clientId': clientId,
      'linkedAt': Timestamp.fromDate(linkedAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class RepRecord {
  final String? id;
  final int repNumber;
  final String exerciseName;
  final double formScore;
  final bool isValid;
  final List<String> errorsDetected;
  final double primaryAngle;
  final DateTime timestamp;
  final double weightUsed;

  RepRecord({
    this.id,
    required this.repNumber,
    required this.exerciseName,
    required this.formScore,
    required this.isValid,
    required this.errorsDetected,
    required this.primaryAngle,
    required this.timestamp,
    required this.weightUsed,
  });

  factory RepRecord.fromMap(Map<String, dynamic> data, String documentId) {
    return RepRecord(
      id: documentId,
      repNumber: data['repNumber'] ?? 0,
      exerciseName: data['exerciseName'] ?? '',
      formScore: (data['formScore'] ?? 0).toDouble(),
      isValid: data['isValid'] ?? false,
      errorsDetected: List<String>.from(data['errorsDetected'] ?? []),
      primaryAngle: (data['primaryAngle'] ?? 0).toDouble(),
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
      weightUsed: (data['weightUsed'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'repNumber': repNumber,
      'exerciseName': exerciseName,
      'formScore': formScore,
      'isValid': isValid,
      'errorsDetected': errorsDetected,
      'primaryAngle': primaryAngle,
      'timestamp': Timestamp.fromDate(timestamp),
      'weightUsed': weightUsed,
    };
  }
}

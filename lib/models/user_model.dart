import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final double heightCm;
  final double weightKg;
  final int age;
  final double bmi;
  final String fitnessGoal;
  final String role; // 'user' or 'trainer'
  final DateTime createdAt;
  final int streakCount;
  final DateTime? lastActiveDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.bmi,
    required this.fitnessGoal,
    required this.role,
    required this.createdAt,
    required this.streakCount,
    this.lastActiveDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      heightCm: (data['heightCm'] ?? 0).toDouble(),
      weightKg: (data['weightKg'] ?? 0).toDouble(),
      age: data['age'] ?? 0,
      bmi: (data['bmi'] ?? 0).toDouble(),
      fitnessGoal: data['fitnessGoal'] ?? '',
      role: data['role'] ?? 'user',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      streakCount: data['streakCount'] ?? 0,
      lastActiveDate: data['lastActiveDate'] != null ? (data['lastActiveDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'age': age,
      'bmi': bmi,
      'fitnessGoal': fitnessGoal,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'streakCount': streakCount,
      'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
    };
  }
}

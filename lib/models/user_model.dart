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
  final String? profilePhotoUrl;
  final String? contactNumber;
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
    this.profilePhotoUrl,
    this.contactNumber,
    required this.createdAt,
    required this.streakCount,
    this.lastActiveDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      heightCm: _parseDouble(data['heightCm']),
      weightKg: _parseDouble(data['weightKg']),
      age: _parseInt(data['age']),
      bmi: _parseDouble(data['bmi']),
      fitnessGoal: data['fitnessGoal']?.toString() ?? '',
      role: data['role']?.toString() ?? 'user',
      profilePhotoUrl: data['profilePhotoUrl']?.toString(),
      contactNumber: data['contactNumber']?.toString(),
      createdAt: data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      streakCount: _parseInt(data['streakCount']),
      lastActiveDate: data['lastActiveDate'] is Timestamp ? (data['lastActiveDate'] as Timestamp).toDate() : null,
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
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
      'profilePhotoUrl': profilePhotoUrl,
      'contactNumber': contactNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'streakCount': streakCount,
      'lastActiveDate': lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
    };
  }
}

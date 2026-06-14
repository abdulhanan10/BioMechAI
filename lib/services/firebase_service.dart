import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/workout_session_model.dart';
import '../models/exercise_block.dart';
import '../models/rep_record.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await getUserData(user.uid);
    }
    return null;
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        return await getUserData(cred.user!.uid);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required double heightCm,
    required double weightKg,
    required int age,
    required String fitnessGoal,
    required String role,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        double bmi = weightKg / ((heightCm / 100) * (heightCm / 100));
        UserModel newUser = UserModel(
          uid: cred.user!.uid,
          email: email,
          name: name,
          heightCm: heightCm,
          weightKg: weightKg,
          age: age,
          bmi: bmi,
          fitnessGoal: fitnessGoal,
          role: role,
          createdAt: DateTime.now(),
          streakCount: 0,
        );
        await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  Future<void> updateLastActive(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastActiveDate': FieldValue.serverTimestamp(),
    });
  }

  Future<String> saveWorkoutSession(SessionModel session) async {
    try {
      DocumentReference docRef = _firestore
          .collection('users')
          .doc(session.userId)
          .collection('workout_sessions')
          .doc(session.sessionId);
      
      await docRef.set(session.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveExerciseBlock(String userId, String sessionId, ExerciseBlock block) async {
    try {
      CollectionReference colRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .doc(sessionId)
          .collection('exercises');
      
      if (block.id != null && block.id!.isNotEmpty) {
        await colRef.doc(block.id).set(block.toMap());
      } else {
        await colRef.add(block.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveRepRecord(String userId, String sessionId, RepRecord rep) async {
    try {
      CollectionReference colRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .doc(sessionId)
          .collection('reps');
      
      if (rep.id != null && rep.id!.isNotEmpty) {
        await colRef.doc(rep.id).set(rep.toMap());
      } else {
        await colRef.add(rep.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SessionModel>> getRecentSessions(String userId, {int limit = 5}) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workout_sessions')
          .orderBy('sessionDate', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) => SessionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Error getting recent sessions: $e');
      return [];
    }
  }
}

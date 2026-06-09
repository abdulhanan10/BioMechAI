import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    tryAutoLogin();
  }

  Future<void> tryAutoLogin() async {
    _setLoading(true);
    try {
      _currentUser = await _firebaseService.getCurrentUser();
      if (_currentUser != null) {
        await _firebaseService.updateLastActive(_currentUser!.uid);
      }
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _firebaseService.login(email, password);
      if (_currentUser != null) {
        await _firebaseService.updateLastActive(_currentUser!.uid);
      }
      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required double heightCm,
    required double weightKg,
    required int age,
    required String fitnessGoal,
    required String role,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _firebaseService.register(
        email: email,
        password: password,
        name: name,
        heightCm: heightCm,
        weightKg: weightKg,
        age: age,
        fitnessGoal: fitnessGoal,
        role: role,
      );
      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

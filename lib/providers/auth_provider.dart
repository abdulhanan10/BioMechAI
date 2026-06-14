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
      _error = _getFriendlyErrorMessage(e.toString());
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
      _error = _getFriendlyErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _firebaseService.resetPassword(email);
      _setLoading(false);
    } catch (e) {
      _error = _getFriendlyErrorMessage(e.toString(), isReset: true);
      _setLoading(false);
      throw Exception(_error);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> reloadUser() async {
    if (_currentUser == null) return;
    try {
      _currentUser = await _firebaseService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Error reloading user: $e');
    }
  }

  String _getFriendlyErrorMessage(String errorString, {bool isReset = false}) {
    if (errorString.contains('invalid-credential') || errorString.contains('wrong-password')) {
      return isReset ? 'This email is not registered.' : 'Incorrect email or password.';
    } else if (errorString.contains('user-not-found')) {
      return 'This email is not registered.';
    } else if (errorString.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (errorString.contains('weak-password')) {
      return 'The password provided is too weak.';
    } else if (errorString.contains('invalid-email')) {
      return 'The email address is badly formatted.';
    }
    
    // Clean up generic firebase tags
    return errorString.replaceAll(RegExp(r'\[.*?\] '), '').replaceAll('Exception: ', '');
  }
}

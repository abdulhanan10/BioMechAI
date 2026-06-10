import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _feedbackSubscription;
  BuildContext? _context;
  bool _isFirstSnapshot = true;
  
  final Set<String> _notifiedFeedbackIds = {};

  Future<void> initialize(BuildContext context) async {
    _context = context;

    try {
      await _fcm.requestPermission();
    } catch (e) {
      debugPrint("FCM Permission error: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);
    
    await _localNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'New Notification',
          message.notification!.body ?? '',
        );
      }
    });

    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _startListeningToFeedback(user.uid);
      } else {
        _stopListeningToFeedback();
      }
    });
  }

  void _startListeningToFeedback(String uid) {
    _feedbackSubscription?.cancel();
    _isFirstSnapshot = true;
    
    _feedbackSubscription = _db
        .collection('users')
        .doc(uid)
        .collection('workout_sessions')
        .orderBy('sessionDate', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        
        final feedback = data['trainerFeedback'] as String?;
        final sessionId = change.doc.id;
        
        if (feedback != null && feedback.isNotEmpty) {
          final notificationId = '$sessionId-${feedback.hashCode}';
          
          if (_isFirstSnapshot) {
             _notifiedFeedbackIds.add(notificationId);
          } else if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
             if (!_notifiedFeedbackIds.contains(notificationId)) {
                _notifiedFeedbackIds.add(notificationId);
                _showTrainerFeedbackNotification(feedback);
             }
          }
        }
      }
      
      _isFirstSnapshot = false;
    });
  }

  void _stopListeningToFeedback() {
    _feedbackSubscription?.cancel();
    _feedbackSubscription = null;
    _notifiedFeedbackIds.clear();
  }

  Future<void> _showTrainerFeedbackNotification(String feedback) async {
    await _showLocalNotification('Trainer Feedback Received!', feedback);

    if (_context != null) {
      showDialog(
        context: _context!,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF00F3FF), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.message, color: Color(0xFF00F3FF)),
              SizedBox(width: 8),
              Text('Trainer Feedback', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            feedback,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFF00F3FF), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'biomechai_feedback_channel', 'Trainer Feedback',
            channelDescription: 'Notifications for trainer feedback',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }
}

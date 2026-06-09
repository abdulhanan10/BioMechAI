import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/workout_session_model.dart';
import '../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<SessionModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      final sessions = await _firebaseService.getRecentSessions(auth.currentUser!.uid, limit: 50);
      
      final withFeedback = sessions.where((s) => s.trainerFeedback != null && s.trainerFeedback!.isNotEmpty).toList();
      
      if (mounted) {
        setState(() {
          _notifications = withFeedback;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Trainer Feedback'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No feedback from your trainer yet. Keep working out!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted, fontSize: 16),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final session = _notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.feedback, color: AppTheme.blue, size: 18),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'New Feedback',
                                      style: TextStyle(
                                        color: AppTheme.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(session.sessionDate),
                                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              session.trainerFeedback!,
                              style: const TextStyle(color: AppTheme.text, fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            Divider(color: AppTheme.border.withOpacity(0.5)),
                            const SizedBox(height: 4),
                            Text(
                              'From session: ${session.exerciseCount} exercises • ${session.totalReps} reps',
                              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

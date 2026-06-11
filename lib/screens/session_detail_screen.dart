import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_session_model.dart';
import '../utils/app_theme.dart';
import '../widgets/form_score_ring.dart';

class SessionDetailScreen extends StatelessWidget {
  final SessionModel session;

  const SessionDetailScreen({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  FormScoreRing(score: session.avgFormScore, size: 100),
                  const SizedBox(height: 16),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(session.sessionDate),
                    style: const TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('hh:mm a').format(session.sessionDate),
                    style: const TextStyle(color: AppTheme.muted, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Performance Summary', style: TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildStatRow('Duration', '${session.totalDuration} seconds'),
                  const Divider(color: AppTheme.border, height: 32),
                  _buildStatRow('Total Valid Reps', '${session.totalValidReps}'),
                  const Divider(color: AppTheme.border, height: 32),
                  _buildStatRow('Total Reps', '${session.totalReps}'),
                  const Divider(color: AppTheme.border, height: 32),
                  _buildStatRow('Exercises', session.exerciseNames.isNotEmpty ? session.exerciseNames.join(', ') : '${session.exerciseCount}'),
                ],
              ),
            ),
            if (session.trainerFeedback != null && session.trainerFeedback!.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text('Trainer Feedback', style: TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.blue.withOpacity(0.3)),
                ),
                child: Text(
                  session.trainerFeedback!,
                  style: const TextStyle(color: AppTheme.text, fontSize: 16, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 16)),
        Text(value, style: const TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

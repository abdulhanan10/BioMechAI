import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/workout_session_model.dart';
import '../utils/app_theme.dart';
import '../widgets/session_card.dart';

class HistoryScreen extends StatefulWidget {
  final DateTime? filterDate;
  const HistoryScreen({Key? key, this.filterDate}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<SessionModel> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      final sessions = await _firebaseService.getRecentSessions(auth.currentUser!.uid, limit: 50);
      if (mounted) {
        setState(() {
          if (widget.filterDate != null) {
            _sessions = sessions.where((s) => 
              s.sessionDate.year == widget.filterDate!.year &&
              s.sessionDate.month == widget.filterDate!.month &&
              s.sessionDate.day == widget.filterDate!.day
            ).toList();
          } else {
            _sessions = sessions;
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text(widget.filterDate != null ? 'Sessions for ${widget.filterDate!.month}/${widget.filterDate!.day}' : 'Workout History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('No history yet.', style: TextStyle(color: AppTheme.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    return SessionCard(session: _sessions[index]);
                  },
                ),
    );
  }
}

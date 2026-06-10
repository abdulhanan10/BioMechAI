import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';
import '../models/workout_session_model.dart';
import '../utils/app_theme.dart';
import '../widgets/mini_calendar.dart';
import '../widgets/session_card.dart';
import '../services/notification_service.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<SessionModel> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initialize(context);
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser != null) {
      final sessions = await _firebaseService.getRecentSessions(auth.currentUser!.uid);
      if (mounted) {
        setState(() {
          _recentSessions = sessions;
          _isLoading = false;
        });
      }
    }
  }

  List<String> _getRecommendations(String goal) {
    switch (goal) {
      case 'Weight Loss': return ['Jumping Jack', 'High Knees', 'Squat'];
      case 'Muscle Gain': return ['Squat', 'Push-Up', 'Bicep Curl'];
      case 'Endurance': return ['High Knees', 'Jumping Jack', 'Plank'];
      case 'Flexibility': return ['Lunge', 'Plank', 'Squat'];
      default: return ['Squat', 'Push-Up', 'Plank'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    if (user == null) return const Scaffold(backgroundColor: AppTheme.bg);

    List<DateTime> activeDates = _recentSessions.map((s) => s.sessionDate).toList();
    List<String> recs = _getRecommendations(user.fitnessGoal);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Hello ${user.name.split(' ').first} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.card2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Streak', style: TextStyle(color: AppTheme.muted)),
                              const SizedBox(height: 8),
                              Text('🔥 ${user.streakCount} days', style: const TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.card2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Today', style: TextStyle(color: AppTheme.muted)),
                              const SizedBox(height: 8),
                              Text('${_recentSessions.where((s) => s.sessionDate.day == DateTime.now().day).length} sessions', style: const TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  MiniCalendar(
                    activeDates: activeDates,
                    onDaySelected: (date) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoryScreen(filterDate: date),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.blue, AppTheme.blueDark]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.workout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text('Start Workout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Recommended for You', style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recs.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(recs[index], style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Sessions', style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
                        child: const Text('View All', style: TextStyle(color: AppTheme.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_recentSessions.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No recent sessions', style: TextStyle(color: AppTheme.muted))))
                  else
                    ..._recentSessions.take(5).map((s) => SessionCard(session: s)).toList(),
                ],
              ),
            ),
    );
  }
}

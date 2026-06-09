import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class TrainerDashboardScreen extends StatelessWidget {
  const TrainerDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Trainer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.monitor, size: 80, color: AppTheme.blue),
              SizedBox(height: 24),
              Text(
                'Welcome, Trainer!',
                style: TextStyle(color: AppTheme.text, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Please access the React Web Dashboard on your PC for full trainer features including client management, video playback, and report generation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted, fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

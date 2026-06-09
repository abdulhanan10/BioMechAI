import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) return const Scaffold(backgroundColor: AppTheme.bg);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.blue,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: const TextStyle(color: AppTheme.text, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(user.email, style: const TextStyle(color: AppTheme.muted, fontSize: 16)),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Height', '${user.heightCm} cm'),
                  const Divider(color: AppTheme.border, height: 1),
                  _buildInfoRow('Weight', '${user.weightKg} kg'),
                  const Divider(color: AppTheme.border, height: 1),
                  _buildInfoRow('Age', '${user.age}'),
                  const Divider(color: AppTheme.border, height: 1),
                  _buildInfoRow('BMI', user.bmi.toStringAsFixed(1)),
                  const Divider(color: AppTheme.border, height: 1),
                  _buildInfoRow('Goal', user.fitnessGoal),
                  const Divider(color: AppTheme.border, height: 1),
                  _buildInfoRow('Role', user.role.toUpperCase()),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.red,
                  side: const BorderSide(color: AppTheme.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 16)),
          Text(value, style: const TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

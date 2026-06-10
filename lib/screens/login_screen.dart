import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (success && mounted) {
      if (auth.currentUser?.role == 'trainer') {
        Navigator.pushReplacementNamed(context, AppRoutes.trainer);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.blue.withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(color: AppTheme.blue.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    children: [
                      TextSpan(text: 'BioMech', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'AI', style: TextStyle(color: AppTheme.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome Back',
                  style: TextStyle(color: AppTheme.muted, fontSize: 16),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email, color: AppTheme.muted)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    labelText: 'Password', 
                    prefixIcon: const Icon(Icons.lock, color: AppTheme.muted),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.muted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.blue)),
                  ),
                ),
                const SizedBox(height: 24),
                if (auth.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppTheme.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(auth.error!, style: const TextStyle(color: AppTheme.red)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,
                    child: auth.isLoading ? const CircularProgressIndicator(color: AppTheme.bg) : const Text('Login'),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                  child: const Text('Don\'t have an account? Register', style: TextStyle(color: AppTheme.blue)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

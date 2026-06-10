import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isTrainer = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String _selectedGoal = 'General Fitness';
  final List<String> _goals = ['Weight Loss', 'Muscle Gain', 'Endurance', 'Flexibility', 'General Fitness'];

  Future<void> _register() async {
    if (_passCtrl.text != _confirmPassCtrl.text) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    double h = double.tryParse(_heightCtrl.text) ?? 170.0;
    double w = double.tryParse(_weightCtrl.text) ?? 70.0;
    int a = int.tryParse(_ageCtrl.text) ?? 25;

    bool success = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      heightCm: h,
      weightKg: w,
      age: a,
      fitnessGoal: _selectedGoal,
      role: _isTrainer ? 'trainer' : 'user',
    );

    if (success && mounted) {
      if (_isTrainer) {
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
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.blue.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppTheme.blue.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
                  ],
                  image: const DecorationImage(image: AssetImage('assets/icon.png'), fit: BoxFit.cover),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('User', style: TextStyle(color: AppTheme.text)),
                  Switch(
                    value: _isTrainer,
                    onChanged: (v) => setState(() => _isTrainer = v),
                    activeColor: AppTheme.blue,
                  ),
                  const Text('Trainer', style: TextStyle(color: AppTheme.text)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(controller: _nameCtrl, style: const TextStyle(color: AppTheme.text), decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              TextField(controller: _emailCtrl, style: const TextStyle(color: AppTheme.text), decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppTheme.text),
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.muted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(color: AppTheme.text),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.muted),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (!_isTrainer) ...[
                Row(
                  children: [
                    Expanded(child: TextField(controller: _heightCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.text), decoration: const InputDecoration(labelText: 'Height (cm)'))),
                    const SizedBox(width: 16),
                    Expanded(child: TextField(controller: _weightCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.text), decoration: const InputDecoration(labelText: 'Weight (kg)'))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: _ageCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.text), decoration: const InputDecoration(labelText: 'Age')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGoal,
                  dropdownColor: AppTheme.card,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: const InputDecoration(labelText: 'Fitness Goal'),
                  items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedGoal = v);
                  },
                ),
                const SizedBox(height: 16),
              ],
              
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
                  onPressed: auth.isLoading ? null : _register,
                  child: auth.isLoading ? const CircularProgressIndicator(color: AppTheme.bg) : const Text('Register'),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text('Already have an account? Login', style: TextStyle(color: AppTheme.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

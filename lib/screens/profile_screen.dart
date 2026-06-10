import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage(String uid) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);

      final storageRef = FirebaseStorage.instance.ref().child('profiles/$uid');
      final uploadTask = storageRef.putFile(File(image.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profilePhotoUrl': downloadUrl,
      });

      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.reloadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppTheme.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: AppTheme.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
            GestureDetector(
              onTap: () => _pickAndUploadImage(user.uid),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.blue,
                    backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null,
                    child: user.profilePhotoUrl == null 
                        ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  if (_isUploading)
                    const Positioned.fill(child: CircularProgressIndicator(color: AppTheme.blue)),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppTheme.card, shape: BoxShape.circle, border: Border.all(color: AppTheme.blue, width: 2)),
                    child: const Icon(Icons.edit, size: 16, color: AppTheme.blue),
                  ),
                ],
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
                  if (user.role != 'trainer') ...[
                    _buildInfoRow('Goal', user.fitnessGoal),
                    const Divider(color: AppTheme.border, height: 1),
                  ],
                  if (user.contactNumber != null && user.contactNumber!.isNotEmpty) ...[
                    _buildInfoRow('Contact', user.contactNumber!),
                    const Divider(color: AppTheme.border, height: 1),
                  ],
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

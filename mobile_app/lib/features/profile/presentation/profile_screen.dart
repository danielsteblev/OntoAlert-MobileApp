import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onLogout,
  });

  final UserProfile profile;
  final Future<void> Function({
    required String fullName,
    required String email,
    required String university,
    required String bio,
  }) onSave;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _fullNameController = TextEditingController(text: widget.profile.fullName);
  late final TextEditingController _emailController = TextEditingController(text: widget.profile.email);
  late final TextEditingController _universityController = TextEditingController(text: widget.profile.university);
  late final TextEditingController _bioController = TextEditingController(text: widget.profile.bio);
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        university: _universityController.text.trim(),
        bio: _bioController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.blueAccent.withOpacity(0.2),
          child: const Icon(Icons.person, size: 40),
        ),
        const SizedBox(height: 16),
        Text(widget.profile.username, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'ФИО')),
        const SizedBox(height: 12),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Почта')),
        const SizedBox(height: 12),
        TextField(controller: _universityController, decoration: const InputDecoration(labelText: 'Университет')),
        const SizedBox(height: 12),
        TextField(
          controller: _bioController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'О себе'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Сохраняем...' : 'Сохранить'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: widget.onLogout,
          child: const Text('Выйти'),
        ),
      ],
    );
  }
}

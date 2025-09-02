// profile_settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:characters/characters.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String userName;
  final String phoneNumber;
  final String status;
  final Function(Map<String, String>) onUpdateProfile;
  final String avatarUrl;

  const ProfileSettingsScreen({
    super.key,
    required this.userName,
    required this.phoneNumber,
    required this.status,
    required this.onUpdateProfile,
    required this.avatarUrl,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _statusController;

  String? _localAvatarPath; // локально выбранный файл (галерея)

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _statusController = TextEditingController(text: widget.status);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _localAvatarPath = img.path;
      });
    }
  }

  void _save() {
    final name = _nameController.text.trim();
// Проверяем по графемам (эмодзи/диакритика) — не должен быть пустым
    if (name.characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя')),
      );
      return;
    }

// Собираем обновлённый профиль. Ключи соответствуют ожиданиям Menu.updateProfile
    final updated = <String, String>{
      'newName': name,
      'newPhoneNumber': _phoneController.text.trim(),
      'newStatus': _statusController.text.trim(),
      'avatarUrl': _localAvatarPath != null && _localAvatarPath!.isNotEmpty
          ? _localAvatarPath!
          : widget.avatarUrl,
    };

    widget.onUpdateProfile(updated);
    Navigator.pop(context);
  }

  ImageProvider? _avatarImageProvider() {
// Приоритет: локально выбранный файл -> сетевой URL -> null (иконка-заглушка)
    if (_localAvatarPath != null && _localAvatarPath!.isNotEmpty) {
      final f = File(_localAvatarPath!);
      if (f.existsSync()) return FileImage(f);
    }
    if (widget.avatarUrl.isNotEmpty) {
      return NetworkImage(widget.avatarUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _avatarImageProvider();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Профиль'),
        actions: [
          TextButton(
            onPressed: _save,
            child:
                const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: avatarProvider,
                  backgroundColor: const Color(0xFF3A3A3C),
                  child: avatarProvider == null
                      ? const Icon(Icons.person, color: Colors.white, size: 40)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloatingActionButton.small(
                    heroTag: 'pick_avatar',
                    onPressed: _pickAvatar,
                    backgroundColor: Colors.deepPurple,
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildField(
            label: 'Имя',
            controller: _nameController,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 12),
          _buildField(
            label: 'Телефон',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            // Разрешаем цифры, +, -, пробелы и скобки
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
            ],
          ),
          const SizedBox(height: 12),
          _buildField(
            label: 'Статус',
            controller: _statusController,
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF2A2A2E),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.deepPurple),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

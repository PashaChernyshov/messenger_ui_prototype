import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:app_design/app/state/app_state.dart';
import 'package:app_design/core/ui/corporate_ui.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final statusController = TextEditingController();

  Uint8List? avatarBytes;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    nameController.text = app.profile.name;
    phoneController.text = app.profile.phone;
    statusController.text = app.profile.status;
    avatarBytes = app.profile.avatarBytes;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = nameController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          TextButton(
            onPressed: canSave ? _save : null,
            child: const Text('Сохранить'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: CorporateUi.pagePadding,
        children: [
          CorporatePanel(
            child: Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.14),
                    backgroundImage:
                        avatarBytes == null ? null : MemoryImage(avatarBytes!),
                    child: avatarBytes == null
                        ? const Icon(Icons.person, size: 44)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Row(
                      children: [
                        IconButton.filled(
                          tooltip: 'Выбрать фото',
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.photo_camera_outlined),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          tooltip: 'Удалить',
                          onPressed: avatarBytes == null ? null : _clearAvatar,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _Field(
            label: 'Имя',
            controller: nameController,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _Field(label: 'Телефон', controller: phoneController),
          const SizedBox(height: 12),
          _Field(label: 'Статус', controller: statusController),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;

    final bytes = await x.readAsBytes();
    setState(() => avatarBytes = bytes);
  }

  void _clearAvatar() {
    setState(() => avatarBytes = null);
  }

  void _save() {
    Navigator.pop<Map<String, dynamic>>(context, {
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'status': statusController.text.trim(),
      'avatarBytes': avatarBytes,
      'clearAvatar': avatarBytes == null,
    });
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.label,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}


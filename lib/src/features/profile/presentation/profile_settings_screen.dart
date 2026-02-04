import 'dart:typed_data';
import 'dart:ui';

import 'package:characters/characters.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../profile/controller/profile_controller.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();

  Uint8List? avatar;

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileController>().profile;
    name.text = p.name;
    phone.text = p.phone; // phone НЕ nullable
    avatar = p.avatarBytes;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = Color.lerp(Colors.black, cs.surface, 0.22)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 64,
        title: Text(
          'Профиль',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12 + 64, 14, 18),
          children: [
            _GlassCard(
              child: Column(
                children: [
                  _Avatar(
                    bytes: avatar,
                    initials: _initials(name.text),
                    accent: Color.lerp(cs.primary, cs.onSurface, 0.45)!,
                    onPick: _pickAvatar,
                    onRemove: () => setState(() => avatar = null),
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'Имя',
                    controller: name,
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    label: 'Телефон',
                    controller: phone,
                    icon: Icons.phone_rounded,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await profile.save(
                          name: name.text,
                          phone: phone.text,
                          avatarBytes: avatar,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Сохранено')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Сохранить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String s) {
    final t = s.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    final a = parts.first.characters.take(1).toString().toUpperCase();
    final b = parts.last.characters.take(1).toString().toUpperCase();
    return '$a$b';
  }

  Future<void> _pickAvatar() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = res?.files.single.bytes;
    if (bytes == null) return;
    setState(() => avatar = bytes);
  }
}

/* ===== glass UI ===== */

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.45),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.onSurface.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 26,
                spreadRadius: -10,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      style: TextStyle(
        color: cs.onSurface.withOpacity(0.92),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.onSurface.withOpacity(0.60)),
        filled: true,
        fillColor: cs.surface.withOpacity(0.35),
        labelStyle: TextStyle(
          color: cs.onSurface.withOpacity(0.58),
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.18)),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Uint8List? bytes;
  final String initials;
  final Color accent;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _Avatar({
    required this.bytes,
    required this.initials,
    required this.accent,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.92),
                accent.withOpacity(0.18),
              ],
            ),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: cs.surface.withOpacity(0.55),
            backgroundImage: bytes == null ? null : MemoryImage(bytes!),
            child: bytes == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface.withOpacity(0.90),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Выбрать фото'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Убрать'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

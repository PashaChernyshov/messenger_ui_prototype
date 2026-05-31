import 'package:flutter/material.dart';

import '../../groups/presentation/group_creation_screen.dart';
import '../../profile/presentation/profile_settings_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'menu_widget.dart';

Future<void> showAppMenuSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => const _AppMenuSheet(),
  );
}

class _AppMenuSheet extends StatelessWidget {
  const _AppMenuSheet();

  @override
  Widget build(BuildContext context) {
    return MenuWidget(
      title: 'Меню',
      items: [
        _SectionLabel('Действия'),
        _Action(
          icon: Icons.group_add_rounded,
          title: 'Создать группу',
          subtitle: 'Создание новой группы',
          tint: _ActionTint.blue,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupCreationScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _SectionLabel('Профиль и настройки'),
        _Action(
          icon: Icons.person_rounded,
          title: 'Профиль',
          subtitle: 'Имя, телефон, аватар',
          tint: _ActionTint.neutral,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
            );
          },
        ),
        _Action(
          icon: Icons.settings_rounded,
          title: 'Настройки',
          subtitle: 'XMPP параметры подключения',
          tint: _ActionTint.neutral,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: cs.onSurface.withOpacity(0.55),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

enum _ActionTint { neutral, purple, blue, green, red }

class _Action extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final _ActionTint tint;

  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color accent = switch (tint) {
      _ActionTint.purple => cs.primary,
      _ActionTint.blue => Colors.lightBlueAccent.shade100,
      _ActionTint.green => Colors.greenAccent.shade200,
      _ActionTint.red => Colors.redAccent.shade100,
      _ActionTint.neutral => cs.onSurface.withOpacity(0.75),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 26,
                spreadRadius: -10,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.22),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(0.90),
                          accent.withOpacity(0.22),
                        ],
                      ),
                      border: Border.all(color: cs.onSurface.withOpacity(0.08)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.68),
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurface.withOpacity(0.38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

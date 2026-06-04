import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_design/app/state/app_state.dart';
import 'package:app_design/features/groups/presentation/group_creation_screen.dart';
import 'package:app_design/features/shell/presentation/menu/menu_widget.dart';
import 'package:app_design/features/profile/presentation/profile_settings_screen.dart';
import 'package:app_design/features/settings/presentation/settings_screen.dart';

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
    final app = context.watch<AppState>();

    return MenuWidget(
      title: '\u041c\u0435\u043d\u044e',
      items: [
        _SectionLabel('\u0414\u0435\u0439\u0441\u0442\u0432\u0438\u044f'),
        _Action(
          icon: Icons.add_comment_rounded,
          title:
              '\u041d\u043e\u0432\u044b\u0439 \u0447\u0430\u0442 (\u0434\u0435\u043c\u043e)',
          subtitle:
              '\u0421\u043e\u0437\u0434\u0430\u0435\u0442 \u043b\u043e\u043a\u0430\u043b\u044c\u043d\u0443\u044e \u0437\u0430\u043f\u0438\u0441\u044c \u0447\u0430\u0442\u0430',
          tint: _ActionTint.accent,
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '\u0418\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0439 \u043a\u043d\u043e\u043f\u043a\u0443 \u041d\u043e\u0432\u044b\u0439 \u0447\u0430\u0442 \u0432\u043e \u0432\u043a\u043b\u0430\u0434\u043a\u0435 \u0427\u0430\u0442\u044b.'),
              ),
            );
          },
        ),
        _Action(
          icon: Icons.group_add_rounded,
          title:
              '\u041d\u043e\u0432\u0430\u044f \u0433\u0440\u0443\u043f\u043f\u0430',
          subtitle:
              '\u0421\u043e\u0437\u0434\u0430\u0442\u044c \u043b\u043e\u043a\u0430\u043b\u044c\u043d\u0443\u044e \u0433\u0440\u0443\u043f\u043f\u0443',
          tint: _ActionTint.accent,
          onTap: () async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupCreationScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _SectionLabel(
            '\u041f\u0440\u043e\u0444\u0438\u043b\u044c \u0438 \u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438'),
        _Action(
          icon: Icons.person_rounded,
          title: '\u041f\u0440\u043e\u0444\u0438\u043b\u044c',
          subtitle:
              '\u0418\u043c\u044f, \u0441\u0442\u0430\u0442\u0443\u0441, \u0430\u0432\u0430\u0442\u0430\u0440',
          tint: _ActionTint.neutral,
          onTap: () async {
            Navigator.pop(context);
            final res = await Navigator.push<Map<String, dynamic>?>(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
            );
            if (res == null) return;
            final next = app.profile.copyWith(
              name: (res['name'] ?? app.profile.name).toString(),
              phone: (res['phone'] ?? app.profile.phone).toString(),
              status: (res['status'] ?? app.profile.status).toString(),
              avatarBytes: res['avatarBytes'],
              clearAvatar: res['clearAvatar'] == true,
            );
            await app.updateProfile(next);
          },
        ),
        _Action(
          icon: Icons.settings_rounded,
          title: '\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438',
          subtitle:
              '\u0418\u043d\u0442\u0435\u0440\u0444\u0435\u0439\u0441 + XMPP',
          tint: _ActionTint.neutral,
          onTap: () async {
            Navigator.pop(context);
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
          child: Text(
            '\u0420\u0435\u0436\u0438\u043c \u043f\u0440\u043e\u0442\u043e\u0442\u0438\u043f\u0430: \u0433\u0440\u0443\u043f\u043f\u044b \u043b\u043e\u043a\u0430\u043b\u044c\u043d\u044b\u0435; \u0444\u0430\u0439\u043b\u044b \u043e\u0442\u043f\u0440\u0430\u0432\u043b\u044f\u044e\u0442\u0441\u044f \u043a\u0430\u043a \u0443\u0432\u0435\u0434\u043e\u043c\u043b\u0435\u043d\u0438\u044f.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.62),
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
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

enum _ActionTint { neutral, accent, green, red }

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
      _ActionTint.accent => cs.primary,
      _ActionTint.green => const Color(0xFF7E9D83),
      _ActionTint.red => const Color(0xFFD47A7A),
      _ActionTint.neutral => cs.onSurface.withOpacity(0.75),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                spreadRadius: -10,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.22),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: accent.withOpacity(0.14),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
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
                            letterSpacing: 0,
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

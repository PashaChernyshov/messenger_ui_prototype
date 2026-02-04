import 'dart:ui';

import 'package:flutter/material.dart';

import '../../data/contact.dart';

Future<void> showContactInfoPopup(
  BuildContext context, {
  required Contact contact,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => _ContactInfoDialog(contact: contact),
  );
}

class _ContactInfoDialog extends StatelessWidget {
  final Contact contact;
  const _ContactInfoDialog({required this.contact});

  Color _mutedAccent(ColorScheme cs) =>
      Color.lerp(cs.primary, cs.onSurface, 0.45)!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = _mutedAccent(cs);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.70),
                border: Border.all(color: cs.onSurface.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 34,
                    spreadRadius: -10,
                    offset: const Offset(0, 18),
                    color: Colors.black.withOpacity(0.35),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withOpacity(0.90),
                              accent.withOpacity(0.18),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: cs.surface.withOpacity(0.55),
                          child: Text(
                            contact.initials,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface.withOpacity(0.92),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contact.jid,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface.withOpacity(0.62),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Закрыть',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Row(label: 'Статус', value: contact.status ?? '—'),
                  const SizedBox(height: 8),
                  _Row(label: 'Последнее', value: contact.lastMessage ?? '—'),
                  const SizedBox(height: 8),
                  _Row(label: 'Время', value: contact.time ?? '—'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurface.withOpacity(0.60),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withOpacity(0.86),
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

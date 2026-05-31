import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../calls/controller/calls_controller.dart';

class CallsPanel extends StatelessWidget {
  const CallsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final calls = context.watch<CallsController>();
    final list = calls.calls;

    if (list.isEmpty) {
      return const _Stub(
        title: 'Пока нет звонков',
        subtitle: 'Здесь будет список звонков. Сейчас данных нет.',
        icon: Icons.call_outlined,
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = list[i];

        final icon = c.isGroup ? Icons.groups_rounded : Icons.person_rounded;
        final arrow =
            c.outgoing ? Icons.call_made_rounded : Icons.call_received_rounded;
        final status = c.missed ? 'Пропущен' : 'Завершён';

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.45),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 26,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                  color: Colors.black.withOpacity(0.25),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Звонок: ${c.peerName} • $status')),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: cs.surface.withOpacity(0.40),
                        border:
                            Border.all(color: cs.onSurface.withOpacity(0.08)),
                      ),
                      child: Icon(icon, color: cs.onSurface.withOpacity(0.78)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.peerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                arrow,
                                size: 16,
                                color: c.missed
                                    ? Colors.redAccent
                                    : cs.onSurface.withOpacity(0.55),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.onSurface.withOpacity(0.68),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: cs.onSurface.withOpacity(0.08)),
                      ),
                      child: Text(
                        _fmt(c.ts),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.70),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Stub extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _Stub({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.45),
                  border: Border.all(color: cs.onSurface.withOpacity(0.10)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(cs.primary, cs.onSurface, 0.45)!
                                .withOpacity(0.88),
                            Color.lerp(cs.primary, cs.onSurface, 0.45)!
                                .withOpacity(0.18),
                          ],
                        ),
                      ),
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.70),
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

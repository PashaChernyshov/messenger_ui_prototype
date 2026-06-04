import 'package:flutter/material.dart';

class MenuWidget extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const MenuWidget({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: Colors.transparent),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // handle
              Container(
                width: 52,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  _CloseButton(),
                ],
              ),
              const SizedBox(height: 10),

              // content
              ...items,
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: 'Закрыть',
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Icons.close_rounded),
      style: IconButton.styleFrom(
        backgroundColor: cs.surface.withOpacity(0.40),
        foregroundColor: cs.onSurface.withOpacity(0.86),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.transparent),
        ),
      ),
    );
  }
}


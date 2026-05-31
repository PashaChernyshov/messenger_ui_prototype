import 'package:flutter/material.dart';

class CorporateUi {
  static const pagePadding = EdgeInsets.all(16);
  static const sectionGap = SizedBox(height: 16);
  static const itemGap = SizedBox(height: 10);
  static const radius = 8.0;

  static Color border(BuildContext context) => Colors.transparent;

  static Color panel(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color panelAlt(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.38);
}

class CorporatePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const CorporatePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CorporateUi.panel(context),
        borderRadius: BorderRadius.circular(CorporateUi.radius),
        border: Border.all(color: Colors.transparent),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class CorporateSectionTitle extends StatelessWidget {
  final String text;

  const CorporateSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: cs.onSurface.withOpacity(0.62),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class CorporateAvatar extends StatelessWidget {
  final String initials;
  final double radius;

  const CorporateAvatar({
    super.key,
    required this.initials,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primary.withOpacity(0.14),
      foregroundColor: cs.primary,
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

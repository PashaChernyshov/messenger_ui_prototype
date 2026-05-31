import 'package:flutter/material.dart';

class HoverEffect extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;

  const HoverEffect({
    super.key,
    required this.child,
    this.scale = 1.02,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

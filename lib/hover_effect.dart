import 'package:flutter/material.dart';

class HoverEffect extends StatefulWidget {
  final Widget child;
  final void Function()? onTap;
  final double hoverScale;
  final Duration duration;

  const HoverEffect({
    super.key,
    required this.child,
    this.onTap,
    this.hoverScale = 1.02,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? widget.hoverScale : 1.0,
          duration: widget.duration,
          child: widget.child,
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String time;
  final bool showTail;

  const ChatBubble({
    super.key,
    required this.isMe,
    required this.text,
    required this.time,
    this.showTail = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = isMe
        ? Color.lerp(cs.primary, cs.onSurface, 0.55)!.withOpacity(0.38)
        : cs.surface.withOpacity(0.45);

    final border = cs.onSurface.withOpacity(0.10);

    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : (showTail ? 6 : 18)),
      bottomRight: Radius.circular(isMe ? (showTail ? 6 : 18) : 18),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border),
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    spreadRadius: -12,
                    offset: const Offset(0, 14),
                    color: Colors.black.withOpacity(0.22),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.92),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
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

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

class AttachmentPreview extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const AttachmentPreview({
    super.key,
    required this.bytes,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.55),
              border: Border.all(color: cs.onSurface.withOpacity(0.10)),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    bytes,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Вложение готово к отправке',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.86),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Убрать',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: cs.surface.withOpacity(0.30),
                    foregroundColor: cs.onSurface.withOpacity(0.86),
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: cs.onSurface.withOpacity(0.10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

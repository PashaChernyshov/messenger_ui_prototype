import 'dart:ui';

import 'package:flutter/material.dart';

class ChatComposer extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback onPickAttachment;

  const ChatComposer({
    super.key,
    required this.onSend,
    required this.onPickAttachment,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _send() {
    final t = controller.text.trim();
    if (t.isEmpty) return;
    widget.onSend(t);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.62),
                border: Border.all(color: cs.onSurface.withOpacity(0.10)),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Вложение',
                    onPressed: widget.onPickAttachment,
                    icon: const Icon(Icons.attach_file_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surface.withOpacity(0.30),
                      foregroundColor: cs.onSurface.withOpacity(0.86),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.onSurface.withOpacity(0.10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Сообщение…',
                        filled: true,
                        fillColor: cs.surface.withOpacity(0.35),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide:
                              BorderSide(color: cs.onSurface.withOpacity(0.10)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide:
                              BorderSide(color: cs.onSurface.withOpacity(0.10)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide:
                              BorderSide(color: cs.onSurface.withOpacity(0.18)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Отправить',
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surface.withOpacity(0.30),
                      foregroundColor: cs.onSurface.withOpacity(0.92),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.onSurface.withOpacity(0.10)),
                      ),
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

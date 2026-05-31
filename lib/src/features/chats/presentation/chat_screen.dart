import 'dart:ui';

import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String peerJid;
  final String peerName;

  const ChatScreen({
    super.key,
    required this.peerJid,
    required this.peerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Color.lerp(Colors.black, cs.surface, 0.22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 64,
        flexibleSpace: _FrostedBar(
          tint: cs.surface.withOpacity(0.52),
          border: cs.onSurface.withOpacity(0.08),
        ),
        titleSpacing: 14,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.peerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.peerJid,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withOpacity(0.60),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.25),
              (Color.lerp(Colors.black, cs.surface, 0.22)!).withOpacity(0.00),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 12 + 64, 14, 12),
                  children: [
                    _StubBubble(
                      text:
                          'Экран чата подключен. Дальше сюда воткнем реальные сообщения из ChatsController/XMPP.',
                    ),
                  ],
                ),
              ),
              _InputBar(
                controller: _controller,
                onSend: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  _controller.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Отправка (демо): $text')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrostedBar extends StatelessWidget {
  final Color tint;
  final Color border;

  const _FrostedBar({
    required this.tint,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            border: Border(
              bottom: BorderSide(color: border),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.55),
                border: Border.all(color: cs.onSurface.withOpacity(0.10)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.92),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Сообщение…',
                        hintStyle: TextStyle(
                          color: cs.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w700,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Отправить',
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surface.withOpacity(0.35),
                      foregroundColor: cs.onSurface.withOpacity(0.90),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.onSurface.withOpacity(0.08)),
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

class _StubBubble extends StatelessWidget {
  final String text;
  const _StubBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.40),
              border: Border.all(color: cs.onSurface.withOpacity(0.10)),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.82),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

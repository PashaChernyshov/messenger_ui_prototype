import 'dart:ui';

import 'package:flutter/material.dart';

import '../../chats/presentation/widgets/bubble.dart';
import '../../chats/presentation/widgets/composer.dart';

class GroupChatScreen extends StatefulWidget {
  final String title;

  const GroupChatScreen({
    super.key,
    required this.title,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final items = <_Msg>[];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = Color.lerp(Colors.black, cs.surface, 0.22)!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final m = items[i];
                final showTail =
                    i == items.length - 1 || items[i + 1].isMe != m.isMe;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChatBubble(
                    isMe: m.isMe,
                    text: m.text,
                    time: m.time,
                    showTail: showTail,
                  ),
                );
              },
            ),
          ),
          ChatComposer(
            onPickAttachment: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Вложения для групп подключим позже.')),
              );
            },
            onSend: (t) {
              setState(() {
                items.add(_Msg(isMe: true, text: t, time: _now()));
              });
            },
          ),
        ],
      ),
    );
  }

  String _now() {
    final dt = DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Msg {
  final bool isMe;
  final String text;
  final String time;

  _Msg({required this.isMe, required this.text, required this.time});
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:provider/provider.dart';

import 'package:app_design/app/state/app_state.dart';
import 'package:app_design/core/ui/corporate_ui.dart';

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
  static const quickReplies = [
    'Принято',
    'Уточню и вернусь с ответом',
    'Отправлю позже',
    'Спасибо',
  ];

  final controller = TextEditingController();
  final searchController = TextEditingController();
  final scroll = ScrollController();

  bool searchMode = false;
  String? replyToText;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    controller.text = app.draftOf(widget.peerJid);
    controller.addListener(() {
      context.read<AppState>().updateDraft(widget.peerJid, controller.text);
    });
    app.markRead(widget.peerJid);
  }

  @override
  void dispose() {
    controller.dispose();
    searchController.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final settings = app.messageDisplay;
    final q = searchController.text.trim().toLowerCase();
    final messages = app.chatOf(widget.peerJid).where((message) {
      if (q.isEmpty) return true;
      return message.text.toLowerCase().contains(q) ||
          (message.attachmentName ?? '').toLowerCase().contains(q);
    }).toList();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            CorporateAvatar(initials: _initials(widget.peerName), radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (settings.showTechnicalIds)
                    Text(
                      widget.peerJid,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.56),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Поиск в чате',
            onPressed: () => setState(() => searchMode = !searchMode),
            icon: Icon(searchMode ? Icons.search_off_rounded : Icons.search),
          ),
          PopupMenuButton<String>(
            tooltip: 'Действия',
            onSelected: (value) {
              if (value == 'clear') _confirmClearChat(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Очистить локальную историю'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (searchMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по сообщениям',
                ),
              ),
            ),
          _QuickReplies(
            replies: quickReplies,
            onPick: (value) {
              controller.text = value;
              controller.selection = TextSelection.collapsed(
                offset: controller.text.length,
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final message = messages[i];
                return _Bubble(
                  message: message,
                  settings: settings,
                  onReply: () => setState(() {
                    replyToText = message.text.isNotEmpty
                        ? message.text
                        : message.attachmentName ?? 'Вложение';
                  }),
                  onDelete: () => app.deleteMessage(widget.peerJid, message.id),
                  onReact: (reaction) => app.setReaction(
                    widget.peerJid,
                    message.id,
                    reaction,
                  ),
                );
              },
            ),
          ),
          _Composer(
            controller: controller,
            replyToText: replyToText,
            onCancelReply: () => setState(() => replyToText = null),
            onSend: () => _sendText(context),
            onAttach: () => _pickAndSendAttachment(context),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final text = value.trim();
    if (text.isEmpty) return '?';
    final parts = text.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return '${parts.first.characters.take(1)}${parts.last.characters.take(1)}'
        .toUpperCase();
  }

  Future<void> _sendText(BuildContext context) async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();
    final reply = replyToText;
    setState(() => replyToText = null);
    await context.read<AppState>().sendText(
          widget.peerJid,
          text,
          replyToText: reply,
        );
    _scrollDown();
  }

  Future<void> _pickAndSendAttachment(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;

    final file = res.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final caption = controller.text.trim();
    controller.clear();
    final reply = replyToText;
    setState(() => replyToText = null);

    await context.read<AppState>().sendAttachment(
          toJid: widget.peerJid,
          caption: caption,
          bytes: bytes,
          name: file.name,
          mime: file.extension == null
              ? 'application/octet-stream'
              : 'file/${file.extension}',
          replyToText: reply,
        );
    _scrollDown();
  }

  Future<void> _confirmClearChat(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text('Сообщения будут удалены только локально.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<AppState>().clearChat(widget.peerJid);
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent + 240,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }
}

class _QuickReplies extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onPick;

  const _QuickReplies({
    required this.replies,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final text = replies[index];
          return ActionChip(label: Text(text), onPressed: () => onPick(text));
        },
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String? replyToText;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _Composer({
    required this.controller,
    required this.replyToText,
    required this.onCancelReply,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        replyToText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Отменить ответ',
                      onPressed: onCancelReply,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Прикрепить',
                  onPressed: onAttach,
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Сообщение...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onSend,
                    child: const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final MessageDisplaySettings settings;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final ValueChanged<String?> onReact;

  const _Bubble({
    required this.message,
    required this.settings,
    required this.onReply,
    required this.onDelete,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMe = message.isMe;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: settings.messageSpacing),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: () => _showMessageActions(context),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: EdgeInsets.symmetric(
                  horizontal: settings.horizontalMessagePadding,
                  vertical: settings.verticalMessagePadding,
                ),
                decoration: BoxDecoration(
                  color: isMe ? cs.primary.withOpacity(0.16) : cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMe
                        ? cs.primary.withOpacity(0.42)
                        : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.replyToText != null) ...[
                      _ReplyPreview(text: message.replyToText!),
                      const SizedBox(height: 8),
                    ],
                    if (message.attachmentBytes != null &&
                        message.attachmentName != null)
                      _AttachmentPreview(
                        bytes: message.attachmentBytes!,
                        name: message.attachmentName!,
                        mime: message.attachmentMime ?? '',
                      ),
                    if (message.text.isNotEmpty)
                      Linkify(
                        text: message.text,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: settings.messageFontSize,
                        ),
                        linkStyle: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    if (message.reaction != null) ...[
                      const SizedBox(height: 8),
                      Text(message.reaction!,
                          style: const TextStyle(fontSize: 18)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (settings.showMessageTime)
            Text(
              '${_time(message.ts)} • ${message.status}',
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.52),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showMessageActions(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Ответить'),
              onTap: () => Navigator.pop(context, 'reply'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Копировать'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: const Text('Реакция: 👍'),
              onTap: () => Navigator.pop(context, 'like'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: const Text('Реакция: ✅'),
              onTap: () => Navigator.pop(context, 'done'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Удалить локально'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;
    switch (action) {
      case 'reply':
        onReply();
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Текст скопирован')),
          );
        }
        break;
      case 'like':
        onReact(message.reaction == '👍' ? null : '👍');
        break;
      case 'done':
        onReact(message.reaction == '✅' ? null : '✅');
        break;
      case 'delete':
        onDelete();
        break;
    }
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ReplyPreview extends StatelessWidget {
  final String text;

  const _ReplyPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurface.withOpacity(0.70)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final Uint8List bytes;
  final String name;
  final String mime;

  const _AttachmentPreview({
    required this.bytes,
    required this.name,
    required this.mime,
  });

  bool get _looksLikeImage {
    final n = name.toLowerCase();
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: CorporateUi.panelAlt(context),
          child: _looksLikeImage
              ? Image.memory(bytes,
                  fit: BoxFit.cover, height: 180, width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${(bytes.length / 1024).toStringAsFixed(0)} KB',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

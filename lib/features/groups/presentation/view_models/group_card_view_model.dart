import 'package:characters/characters.dart';

import 'package:app_design/features/chat/domain/chat_message.dart';
import 'package:app_design/features/groups/domain/group.dart';

class GroupCardViewModel {
  final String id;
  final String name;
  final String initials;
  final String memberCountText;
  final String createdAtText;
  final String activityText;
  final String statusText;
  final List<String> memberPreview;
  final List<GroupMessagePreview> messagePreview;
  final bool hasMessages;

  const GroupCardViewModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.memberCountText,
    required this.createdAtText,
    required this.activityText,
    required this.statusText,
    required this.memberPreview,
    required this.messagePreview,
    required this.hasMessages,
  });

  factory GroupCardViewModel.from({
    required Group group,
    required List<ChatMessage> messages,
  }) {
    final visibleMessages = messages.where((message) {
      return message.text.trim().isNotEmpty || message.attachmentName != null;
    }).toList();

    final latest = visibleMessages.isEmpty ? null : visibleMessages.last;
    return GroupCardViewModel(
      id: group.id,
      name: group.name,
      initials: _initials(group.name),
      memberCountText: _pluralMembers(group.memberJids.length),
      createdAtText: 'Создана ${_formatDate(group.createdAt)}',
      activityText:
          latest == null ? 'Сообщений пока нет' : _messageLine(latest),
      statusText: 'Локальная группа',
      memberPreview: group.memberJids.take(6).toList(),
      messagePreview: visibleMessages.reversed
          .take(3)
          .map(GroupMessagePreview.fromMessage)
          .toList(),
      hasMessages: visibleMessages.isNotEmpty,
    );
  }

  static String _messageLine(ChatMessage message) {
    final author = message.isMe ? 'Вы' : 'Участник';
    final body = message.text.trim().isEmpty
        ? message.attachmentName ?? 'Вложение'
        : message.text.trim();
    return '$author: $body';
  }

  static String _initials(String value) {
    final text = value.trim();
    if (text.isEmpty) return '?';
    final parts = text.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.take(1).toString();
    return '${parts.first.characters.take(1)}${parts.last.characters.take(1)}'
        .toUpperCase();
  }

  static String _pluralMembers(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return '$count участник';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$count участника';
    }
    return '$count участников';
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day.$month.$year';
  }
}

class GroupMessagePreview {
  final String author;
  final String body;
  final String time;

  const GroupMessagePreview({
    required this.author,
    required this.body,
    required this.time,
  });

  factory GroupMessagePreview.fromMessage(ChatMessage message) {
    final text = message.text.trim();
    return GroupMessagePreview(
      author: message.isMe ? 'Вы' : 'Участник',
      body: text.isEmpty ? message.attachmentName ?? 'Вложение' : text,
      time: _formatTime(message.ts),
    );
  }

  static String _formatTime(DateTime value) {
    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

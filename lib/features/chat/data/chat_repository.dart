import 'dart:typed_data';

import 'package:app_design/features/chat/domain/chat_message.dart';

abstract interface class ChatRepository {
  List<ChatMessage> messagesOf(String peerKey);
  void seedIfEmpty(String peerKey, String displayName);
  void addMessage(String peerKey, ChatMessage message);
  void addMessages(String peerKey, Iterable<ChatMessage> messages);
  void clear(String peerKey);
  void deleteMessage(String peerKey, String messageId);
  void setReaction(String peerKey, String messageId, String? reaction);
  ChatMessage addText({
    required String peerKey,
    required String from,
    required String text,
    String? replyToText,
  });
  ChatMessage addAttachment({
    required String peerKey,
    required String from,
    required String text,
    required Uint8List bytes,
    required String name,
    required String mime,
    String? replyToText,
  });
  String groupPeerKey(String groupId);
}

class InMemoryChatRepository implements ChatRepository {
  final Map<String, List<ChatMessage>> _chats = {};

  @override
  List<ChatMessage> messagesOf(String peerKey) {
    return List.unmodifiable(_chats[peerKey] ?? const []);
  }

  @override
  void seedIfEmpty(String peerKey, String displayName) {
    _chats.putIfAbsent(peerKey, () {
      final now = DateTime.now();
      return [
        ChatMessage(
          id: 'seed-1',
          from: peerKey,
          text: 'Здравствуйте! Чем могу помочь?',
          ts: now.subtract(const Duration(minutes: 12)),
        ),
        ChatMessage(
          id: 'seed-2',
          from: 'me',
          text: 'Добрый день. Нужна информация по вопросу.',
          ts: now.subtract(const Duration(minutes: 10)),
        ),
        ChatMessage(
          id: 'seed-3',
          from: peerKey,
          text: 'Понял. Уточните детали, и я подготовлю ответ.',
          ts: now.subtract(const Duration(minutes: 9)),
        ),
      ];
    });
  }

  @override
  void addMessage(String peerKey, ChatMessage message) {
    _add(peerKey, message);
  }

  @override
  void addMessages(String peerKey, Iterable<ChatMessage> messages) {
    final list = _chats.putIfAbsent(peerKey, () => []);
    final existingIds = list.map((message) => message.id).toSet();
    for (final message in messages) {
      if (existingIds.add(message.id)) {
        list.add(message);
      }
    }
    list.sort((a, b) => a.ts.compareTo(b.ts));
  }

  @override
  void clear(String peerKey) {
    _chats[peerKey] = [];
  }

  @override
  void deleteMessage(String peerKey, String messageId) {
    final list = _chats[peerKey];
    if (list == null) return;
    list.removeWhere((message) => message.id == messageId);
  }

  @override
  void setReaction(String peerKey, String messageId, String? reaction) {
    final list = _chats[peerKey];
    if (list == null) return;
    final index = list.indexWhere((message) => message.id == messageId);
    if (index == -1) return;
    list[index] = list[index].copyWith(
      reaction: reaction,
      clearReaction: reaction == null,
    );
  }

  @override
  ChatMessage addText({
    required String peerKey,
    required String from,
    required String text,
    String? replyToText,
  }) {
    final message = ChatMessage(
      id: 'm-${DateTime.now().microsecondsSinceEpoch}',
      from: from,
      text: text,
      ts: DateTime.now(),
      replyToText: replyToText,
    );
    _add(peerKey, message);
    return message;
  }

  @override
  ChatMessage addAttachment({
    required String peerKey,
    required String from,
    required String text,
    required Uint8List bytes,
    required String name,
    required String mime,
    String? replyToText,
  }) {
    final message = ChatMessage(
      id: 'a-${DateTime.now().microsecondsSinceEpoch}',
      from: from,
      text: text,
      ts: DateTime.now(),
      attachmentBytes: bytes,
      attachmentName: name,
      attachmentMime: mime,
      replyToText: replyToText,
    );
    _add(peerKey, message);
    return message;
  }

  @override
  String groupPeerKey(String groupId) => 'group:$groupId';

  void _add(String peerKey, ChatMessage message) {
    final list = _chats.putIfAbsent(peerKey, () => []);
    list.add(message);
  }
}

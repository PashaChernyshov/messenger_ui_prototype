import 'dart:typed_data';

import 'package:app_design/features/chat/domain/chat_message.dart';

abstract interface class ChatRepository {
  List<ChatMessage> messagesOf(String peerKey);
  void seedIfEmpty(String peerKey, String displayName);
  void addMessage(String peerKey, ChatMessage message);
  void addMessages(String peerKey, Iterable<ChatMessage> messages);
  void clear(String peerKey);
  void deleteMessage(String peerKey, String messageId);
  void updateMessage(String peerKey, String messageId, ChatMessage message);
  void updateMediaProgress(
    String peerKey,
    String messageId, {
    required double progress,
    required String status,
  });
  void failMediaMessage(String peerKey, String messageId, String status);
  void setReaction(String peerKey, String messageId, String? reaction);
  void setTaskStatus(
    String peerKey,
    String messageId,
    MessageTaskStatus? status,
  );
  void setPinned(String peerKey, String messageId, bool pinned);
  ChatMessage addText({
    required String peerKey,
    required String from,
    required String text,
    String? replyToMessageId,
    String? replyToText,
  });
  ChatMessage addAttachment({
    required String peerKey,
    required String from,
    required String text,
    required Uint8List bytes,
    required String name,
    required String mime,
    String? replyToMessageId,
    String? replyToText,
  });
  ChatMessage addVoice({
    required String peerKey,
    required String from,
    required String path,
    required Duration duration,
    String? replyToMessageId,
    String? replyToText,
  });
  ChatMessage addVideoCircle({
    required String peerKey,
    required String from,
    required String path,
    required Duration duration,
    bool mirrorHorizontally = false,
    String? replyToMessageId,
    String? replyToText,
  });
  ChatMessage addPendingMedia({
    required String peerKey,
    required ChatMediaKind kind,
    required Duration duration,
    String? replyToMessageId,
    String? replyToText,
  });
  ChatMessage forwardMessage({
    required String peerKey,
    required ChatMessage source,
    required String forwardedFrom,
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
  void updateMessage(String peerKey, String messageId, ChatMessage message) {
    final list = _chats[peerKey];
    if (list == null) return;
    final index = list.indexWhere((item) => item.id == messageId);
    if (index == -1) return;
    list[index] = message;
  }

  @override
  void updateMediaProgress(
    String peerKey,
    String messageId, {
    required double progress,
    required String status,
  }) {
    final list = _chats[peerKey];
    if (list == null) return;
    final index = list.indexWhere((message) => message.id == messageId);
    if (index == -1) return;
    list[index] = list[index].copyWith(
      mediaProgress: progress.clamp(0.0, 0.99).toDouble(),
      status: status,
      mediaFailed: false,
    );
  }

  @override
  void failMediaMessage(String peerKey, String messageId, String status) {
    final list = _chats[peerKey];
    if (list == null) return;
    final index = list.indexWhere((message) => message.id == messageId);
    if (index == -1) return;
    list[index] = list[index].copyWith(
      mediaProgress: 1,
      status: status,
      mediaFailed: true,
    );
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
  void setTaskStatus(
    String peerKey,
    String messageId,
    MessageTaskStatus? status,
  ) {
    final list = _chats[peerKey];
    if (list == null) return;
    final index = list.indexWhere((message) => message.id == messageId);
    if (index == -1) return;
    list[index] = list[index].copyWith(
      taskStatus: status,
      clearTaskStatus: status == null,
    );
  }

  @override
  void setPinned(String peerKey, String messageId, bool pinned) {
    final list = _chats[peerKey];
    if (list == null) return;
    final index = list.indexWhere((message) => message.id == messageId);
    if (index == -1) return;
    list[index] = list[index].copyWith(isPinned: pinned);
  }

  @override
  ChatMessage addText({
    required String peerKey,
    required String from,
    required String text,
    String? replyToMessageId,
    String? replyToText,
  }) {
    final message = ChatMessage(
      id: 'm-${DateTime.now().microsecondsSinceEpoch}',
      from: from,
      text: text,
      ts: DateTime.now(),
      replyToMessageId: replyToMessageId,
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
    String? replyToMessageId,
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
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    _add(peerKey, message);
    return message;
  }

  @override
  ChatMessage addVoice({
    required String peerKey,
    required String from,
    required String path,
    required Duration duration,
    String? replyToMessageId,
    String? replyToText,
  }) {
    final message = ChatMessage(
      id: 'v-${DateTime.now().microsecondsSinceEpoch}',
      from: from,
      text: '',
      ts: DateTime.now(),
      voicePath: path,
      voiceDuration: duration,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    _add(peerKey, message);
    return message;
  }

  @override
  ChatMessage addVideoCircle({
    required String peerKey,
    required String from,
    required String path,
    required Duration duration,
    bool mirrorHorizontally = false,
    String? replyToMessageId,
    String? replyToText,
  }) {
    final message = ChatMessage(
      id: 'vc-${DateTime.now().microsecondsSinceEpoch}',
      from: from,
      text: '',
      ts: DateTime.now(),
      videoPath: path,
      videoDuration: duration,
      videoMirrorHorizontally: mirrorHorizontally,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    _add(peerKey, message);
    return message;
  }

  @override
  ChatMessage addPendingMedia({
    required String peerKey,
    required ChatMediaKind kind,
    required Duration duration,
    String? replyToMessageId,
    String? replyToText,
  }) {
    final message = ChatMessage(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      from: 'me',
      text: '',
      ts: DateTime.now(),
      voiceDuration: kind == ChatMediaKind.voice ? duration : null,
      videoDuration: kind == ChatMediaKind.videoCircle ? duration : null,
      mediaKind: kind,
      mediaProgress: 0.02,
      status: 'подготовка',
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    _add(peerKey, message);
    return message;
  }

  @override
  String groupPeerKey(String groupId) => 'group:$groupId';

  @override
  ChatMessage forwardMessage({
    required String peerKey,
    required ChatMessage source,
    required String forwardedFrom,
  }) {
    final message = ChatMessage(
      id: 'f-${DateTime.now().microsecondsSinceEpoch}',
      from: 'me',
      text: source.text,
      ts: DateTime.now(),
      attachmentBytes: source.attachmentBytes,
      attachmentName: source.attachmentName,
      attachmentMime: source.attachmentMime,
      voicePath: source.voicePath,
      voiceDuration: source.voiceDuration,
      videoPath: source.videoPath,
      videoDuration: source.videoDuration,
      videoMirrorHorizontally: source.videoMirrorHorizontally,
      forwardedFrom: forwardedFrom,
    );
    _add(peerKey, message);
    return message;
  }

  void _add(String peerKey, ChatMessage message) {
    final list = _chats.putIfAbsent(peerKey, () => []);
    list.add(message);
  }
}

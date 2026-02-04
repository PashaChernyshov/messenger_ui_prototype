import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../xmpp/service/xmpp_service.dart';
import '../data/chat_message.dart';

class ChatsController extends ChangeNotifier {
  final XmppService _xmpp;

  ChatsController(this._xmpp);

  final Map<String, List<ChatMessage>> _chats = {};

  void bootstrap() {}

  List<ChatMessage> chatOf(String peerKey) {
    return _chats[peerKey] ?? const [];
  }

  void ensureChatSeed(String peerKey, String displayName) {
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
          text: 'Понял. Уточните детали — и я подготовлю ответ.',
          ts: now.subtract(const Duration(minutes: 9)),
        ),
      ];
    });
  }

  void addLocalMessage(String peerKey, ChatMessage msg) {
    final list = _chats.putIfAbsent(peerKey, () => []);
    list.add(msg);
    notifyListeners();
  }

  Future<void> sendText(String toJid, String text) async {
    addLocalMessage(
      toJid,
      ChatMessage(
        id: 'm-${DateTime.now().microsecondsSinceEpoch}',
        from: 'me',
        text: text,
        ts: DateTime.now(),
      ),
    );

    await _xmpp.sendMessage(toJid, text);
  }

  Future<void> sendAttachment({
    required String toJid,
    required String caption,
    required Uint8List bytes,
    required String name,
    required String mime,
  }) async {
    final text = caption.isNotEmpty ? caption : '';
    addLocalMessage(
      toJid,
      ChatMessage(
        id: 'a-${DateTime.now().microsecondsSinceEpoch}',
        from: 'me',
        text: text,
        ts: DateTime.now(),
        attachmentBytes: bytes,
        attachmentName: name,
        attachmentMime: mime,
      ),
    );

    final notifyText = [
      if (caption.isNotEmpty) caption,
      '[Вложение] $name (${(bytes.length / 1024).toStringAsFixed(0)} KB)',
    ].join('\n');

    await _xmpp.sendMessage(toJid, notifyText);
  }

  // groups local
  String groupPeerKey(String groupId) => 'group:$groupId';

  void sendGroupLocal(String groupId, String text) {
    addLocalMessage(
      groupPeerKey(groupId),
      ChatMessage(
        id: 'gm-${DateTime.now().microsecondsSinceEpoch}',
        from: 'me',
        text: text,
        ts: DateTime.now(),
      ),
    );
  }
}

import 'dart:typed_data';

class ChatMessage {
  final String id;
  final String from; // "me" or jid
  final String text;
  final DateTime ts;
  final Uint8List? attachmentBytes;
  final String? attachmentName;
  final String? attachmentMime;

  const ChatMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.ts,
    this.attachmentBytes,
    this.attachmentName,
    this.attachmentMime,
  });

  bool get isMe => from == 'me';
}

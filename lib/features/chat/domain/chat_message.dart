import 'dart:typed_data';

class ChatMessage {
  final String id;
  final String from;
  final String text;
  final DateTime ts;
  final Uint8List? attachmentBytes;
  final String? attachmentName;
  final String? attachmentMime;
  final String? replyToText;
  final String? reaction;
  final String status;

  const ChatMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.ts,
    this.attachmentBytes,
    this.attachmentName,
    this.attachmentMime,
    this.replyToText,
    this.reaction,
    this.status = 'локально',
  });

  bool get isMe => from == 'me';

  ChatMessage copyWith({
    String? id,
    String? from,
    String? text,
    DateTime? ts,
    Uint8List? attachmentBytes,
    String? attachmentName,
    String? attachmentMime,
    String? replyToText,
    String? reaction,
    String? status,
    bool clearReaction = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      from: from ?? this.from,
      text: text ?? this.text,
      ts: ts ?? this.ts,
      attachmentBytes: attachmentBytes ?? this.attachmentBytes,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentMime: attachmentMime ?? this.attachmentMime,
      replyToText: replyToText ?? this.replyToText,
      reaction: clearReaction ? null : (reaction ?? this.reaction),
      status: status ?? this.status,
    );
  }
}

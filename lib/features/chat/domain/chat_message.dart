import 'dart:typed_data';

enum MessageTaskStatus {
  newItem('Новое'),
  inProgress('В работе'),
  waiting('Ждем ответа'),
  done('Готово'),
  rejected('Отклонено');

  final String label;

  const MessageTaskStatus(this.label);
}

enum ChatMediaKind { voice, videoCircle }

class ChatMessage {
  final String id;
  final String from;
  final String text;
  final DateTime ts;
  final Uint8List? attachmentBytes;
  final String? attachmentName;
  final String? attachmentMime;
  final String? voicePath;
  final Duration? voiceDuration;
  final String? videoPath;
  final Duration? videoDuration;
  final bool videoMirrorHorizontally;
  final String? replyToMessageId;
  final String? replyToText;
  final String? forwardedFrom;
  final String? reaction;
  final String status;
  final MessageTaskStatus? taskStatus;
  final bool isPinned;
  final ChatMediaKind? mediaKind;
  final double? mediaProgress;
  final bool mediaFailed;

  const ChatMessage({
    required this.id,
    required this.from,
    required this.text,
    required this.ts,
    this.attachmentBytes,
    this.attachmentName,
    this.attachmentMime,
    this.voicePath,
    this.voiceDuration,
    this.videoPath,
    this.videoDuration,
    this.videoMirrorHorizontally = false,
    this.replyToMessageId,
    this.replyToText,
    this.forwardedFrom,
    this.reaction,
    this.status = 'локально',
    this.taskStatus,
    this.isPinned = false,
    this.mediaKind,
    this.mediaProgress,
    this.mediaFailed = false,
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
    String? voicePath,
    Duration? voiceDuration,
    String? videoPath,
    Duration? videoDuration,
    bool? videoMirrorHorizontally,
    String? replyToMessageId,
    String? replyToText,
    String? forwardedFrom,
    String? reaction,
    String? status,
    MessageTaskStatus? taskStatus,
    bool? isPinned,
    ChatMediaKind? mediaKind,
    double? mediaProgress,
    bool? mediaFailed,
    bool clearReaction = false,
    bool clearTaskStatus = false,
    bool clearMediaProgress = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      from: from ?? this.from,
      text: text ?? this.text,
      ts: ts ?? this.ts,
      attachmentBytes: attachmentBytes ?? this.attachmentBytes,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentMime: attachmentMime ?? this.attachmentMime,
      voicePath: voicePath ?? this.voicePath,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      videoPath: videoPath ?? this.videoPath,
      videoDuration: videoDuration ?? this.videoDuration,
      videoMirrorHorizontally:
          videoMirrorHorizontally ?? this.videoMirrorHorizontally,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      reaction: clearReaction ? null : (reaction ?? this.reaction),
      status: status ?? this.status,
      taskStatus: clearTaskStatus ? null : (taskStatus ?? this.taskStatus),
      isPinned: isPinned ?? this.isPinned,
      mediaKind: mediaKind ?? this.mediaKind,
      mediaProgress:
          clearMediaProgress ? null : (mediaProgress ?? this.mediaProgress),
      mediaFailed: mediaFailed ?? this.mediaFailed,
    );
  }
}

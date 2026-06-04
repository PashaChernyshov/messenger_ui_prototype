import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import 'package:app_design/app/state/app_state.dart';
import 'package:app_design/core/ui/corporate_ui.dart';
import 'package:app_design/features/chat/presentation/widgets/video_circle_player.dart';
import 'package:app_design/features/chat/presentation/widgets/voice_message_player.dart';

enum _CaptureMode { voice, video }

enum _AttachmentKind { photo, video, audio, file }

class _VideoSegment {
  final String path;
  final bool mirrorHorizontally;

  const _VideoSegment({
    required this.path,
    required this.mirrorHorizontally,
  });
}

class _ForwardTarget {
  final String peerKey;
  final String title;
  final String subtitle;

  const _ForwardTarget({
    required this.peerKey,
    required this.title,
    required this.subtitle,
  });
}

const List<String> _defaultReactionEmojis = [
  '👍',
  '❤️',
  '🔥',
  '👏',
  '😁',
  '🤝',
  '👌',
  '✅',
  '🙏',
  '💯',
  '👀',
  '🤔',
  '😎',
  '😮',
  '😢',
  '🎉',
  '🚀',
  '⚡',
  '📌',
  '❗',
];

const List<String> _allReactionEmojis = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😆',
  '😅',
  '😂',
  '🤣',
  '🙂',
  '🙃',
  '😉',
  '😊',
  '😇',
  '🥰',
  '😍',
  '🤩',
  '😘',
  '😗',
  '😚',
  '😙',
  '😋',
  '😛',
  '😜',
  '🤪',
  '😝',
  '🤑',
  '🤗',
  '🤭',
  '🫢',
  '🫣',
  '🤫',
  '🤔',
  '🫡',
  '🤐',
  '🤨',
  '😐',
  '😑',
  '😶',
  '🫥',
  '😏',
  '😒',
  '🙄',
  '😬',
  '😮‍💨',
  '🤥',
  '😌',
  '😔',
  '😪',
  '🤤',
  '😴',
  '😷',
  '🤒',
  '🤕',
  '🤢',
  '🤮',
  '🤧',
  '🥵',
  '🥶',
  '🥴',
  '😵',
  '🤯',
  '🤠',
  '🥳',
  '🥸',
  '😎',
  '🤓',
  '🧐',
  '😕',
  '🫤',
  '😟',
  '🙁',
  '☹️',
  '😮',
  '😯',
  '😲',
  '😳',
  '🥺',
  '🥹',
  '😦',
  '😧',
  '😨',
  '😰',
  '😥',
  '😢',
  '😭',
  '😱',
  '😖',
  '😣',
  '😞',
  '😓',
  '😩',
  '😫',
  '🥱',
  '😤',
  '😡',
  '😠',
  '🤬',
  '😈',
  '👿',
  '💀',
  '☠️',
  '💩',
  '🤡',
  '👻',
  '👽',
  '🤖',
  '😺',
  '😸',
  '😹',
  '😻',
  '😼',
  '😽',
  '🙀',
  '😿',
  '😾',
  '👍',
  '👎',
  '👌',
  '🤌',
  '🤏',
  '✌️',
  '🤞',
  '🫰',
  '🤟',
  '🤘',
  '🤙',
  '👈',
  '👉',
  '👆',
  '👇',
  '☝️',
  '✋',
  '🤚',
  '🖐️',
  '🖖',
  '👋',
  '🤝',
  '👏',
  '🙌',
  '🫶',
  '👐',
  '🤲',
  '🙏',
  '✍️',
  '💪',
  '🦾',
  '🦵',
  '🦶',
  '👂',
  '👃',
  '🧠',
  '🫀',
  '🫁',
  '👀',
  '👁️',
  '👅',
  '👄',
  '💋',
  '🩸',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🖤',
  '🤍',
  '🤎',
  '💔',
  '❣️',
  '💕',
  '💞',
  '💓',
  '💗',
  '💖',
  '💘',
  '💝',
  '💟',
  '☮️',
  '✝️',
  '☪️',
  '🕉️',
  '☸️',
  '✡️',
  '🔯',
  '☯️',
  '☦️',
  '🛐',
  '⛎',
  '♈',
  '♉',
  '♊',
  '♋',
  '♌',
  '♍',
  '♎',
  '♏',
  '♐',
  '♑',
  '♒',
  '♓',
  '🆔',
  '⚛️',
  '🉑',
  '☢️',
  '☣️',
  '📴',
  '📳',
  '🈶',
  '🈚',
  '🈸',
  '🈺',
  '🈷️',
  '✴️',
  '🆚',
  '💮',
  '🉐',
  '㊙️',
  '㊗️',
  '🈴',
  '🈵',
  '🈹',
  '🈲',
  '🅰️',
  '🅱️',
  '🆎',
  '🆑',
  '🅾️',
  '🆘',
  '❌',
  '⭕',
  '🛑',
  '⛔',
  '📛',
  '🚫',
  '💯',
  '💢',
  '♨️',
  '🚷',
  '🚯',
  '🚳',
  '🚱',
  '🔞',
  '📵',
  '🚭',
  '❗',
  '❕',
  '❓',
  '❔',
  '‼️',
  '⁉️',
  '🔅',
  '🔆',
  '〽️',
  '⚠️',
  '🚸',
  '🔱',
  '⚜️',
  '🔰',
  '♻️',
  '✅',
  '🈯',
  '💹',
  '❇️',
  '✳️',
  '❎',
  '🌐',
  '💠',
  'Ⓜ️',
  '🌀',
  '💤',
  '🏧',
  '🚾',
  '♿',
  '🅿️',
  '🛗',
  '🈳',
  '🈂️',
  '🛂',
  '🛃',
  '🛄',
  '🛅',
  '🚹',
  '🚺',
  '🚼',
  '⚧️',
  '🚻',
  '🚮',
  '🎦',
  '📶',
  '🈁',
  '🔣',
  'ℹ️',
  '🔤',
  '🔡',
  '🔠',
  '🆖',
  '🆗',
  '🆙',
  '🆒',
  '🆕',
  '🆓',
  '0️⃣',
  '1️⃣',
  '2️⃣',
  '3️⃣',
  '4️⃣',
  '5️⃣',
  '6️⃣',
  '7️⃣',
  '8️⃣',
  '9️⃣',
  '🔟',
  '🔢',
  '#️⃣',
  '*️⃣',
  '⏏️',
  '▶️',
  '⏸️',
  '⏯️',
  '⏹️',
  '⏺️',
  '⏭️',
  '⏮️',
  '⏩',
  '⏪',
  '⏫',
  '⏬',
  '◀️',
  '🔼',
  '🔽',
  '➡️',
  '⬅️',
  '⬆️',
  '⬇️',
  '↗️',
  '↘️',
  '↙️',
  '↖️',
  '↕️',
  '↔️',
  '↪️',
  '↩️',
  '⤴️',
  '⤵️',
  '🔀',
  '🔁',
  '🔂',
  '🔄',
  '🔃',
  '🎵',
  '🎶',
  '➕',
  '➖',
  '➗',
  '✖️',
  '🟰',
  '♾️',
  '💲',
  '💱',
  '™️',
  '©️',
  '®️',
  '〰️',
  '➰',
  '➿',
  '🔚',
  '🔙',
  '🔛',
  '🔝',
  '🔜',
  '☑️',
  '🔘',
  '🔴',
  '🟠',
  '🟡',
  '🟢',
  '🔵',
  '🟣',
  '⚫',
  '⚪',
  '🟤',
  '🔺',
  '🔻',
  '🔸',
  '🔹',
  '🔶',
  '🔷',
  '🔳',
  '🔲',
  '▪️',
  '▫️',
  '◾',
  '◽',
  '◼️',
  '◻️',
  '🟥',
  '🟧',
  '🟨',
  '🟩',
  '🟦',
  '🟪',
  '⬛',
  '⬜',
  '🟫',
  '🔈',
  '🔇',
  '🔉',
  '🔊',
  '🔔',
  '🔕',
  '📣',
  '📢',
  '💬',
  '💭',
  '🗯️',
  '♠️',
  '♣️',
  '♥️',
  '♦️',
  '🃏',
  '🎴',
  '🀄',
  '🕐',
  '🕑',
  '🕒',
  '🕓',
  '🕔',
  '🕕',
  '🕖',
  '🕗',
  '🕘',
  '🕙',
  '🕚',
  '🕛',
  '⭐',
  '🌟',
  '✨',
  '⚡',
  '🔥',
  '💥',
  '🌈',
  '☀️',
  '🌤️',
  '⛅',
  '🌧️',
  '❄️',
  '☕',
  '🍕',
  '🍔',
  '🍟',
  '🍎',
  '🍌',
  '🍇',
  '🍓',
  '🎂',
  '🍫',
  '⚽',
  '🏀',
  '🎮',
  '🎯',
  '🏆',
  '🥇',
  '🎁',
  '🎉',
  '🎊',
  '💼',
  '📎',
  '📌',
  '📍',
  '📝',
  '📄',
  '📊',
  '📈',
  '📉',
  '📅',
  '📞',
  '📧',
  '🔒',
  '🔓',
  '🔑',
  '🧩',
  '🛠️',
  '⚙️',
  '🚀',
];

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
  final controller = TextEditingController();
  final searchController = TextEditingController();
  final scroll = ScrollController();
  final recorder = AudioRecorder();

  CameraController? cameraController;
  List<CameraDescription> videoCameras = const [];
  final List<_VideoSegment> videoSegments = [];
  CameraDescription? activeCameraDescription;
  Timer? recordTimer;
  StreamSubscription<Amplitude>? micAmplitudeSub;

  bool searchMode = false;
  bool isRecording = false;
  bool isCaptureStarting = false;
  bool isCaptureFinishing = false;
  bool recordLocked = false;
  bool recordCancelled = false;
  double lockDragProgress = 0;
  bool? pendingCaptureSend;
  bool pendingCaptureFinishFromHold = false;
  String? replyToMessageId;
  String? replyToText;
  String? highlightedMessageId;
  int pinnedMessageCursor = 0;
  final Map<String, GlobalKey> messageKeys = {};
  Duration recordDuration = Duration.zero;
  DateTime? recordStartedAt;
  double lastMicAmplitude = -160;
  bool keepVideoCameraAlive = false;
  bool videoTorchEnabled = false;
  bool screenFlashEnabled = false;
  bool isSwitchingVideoCamera = false;
  bool isChangingVideoFlash = false;
  bool videoRecordedWithFrontCamera = false;
  double videoZoomLevel = 1;
  double videoMinZoomLevel = 1;
  double videoMaxZoomLevel = 1;
  double videoZoomLevelOnGestureStart = 1;
  _CaptureMode captureMode = _CaptureMode.voice;
  _CaptureMode activeCaptureMode = _CaptureMode.voice;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    controller.text = app.draftOf(widget.peerJid);
    controller.addListener(() {
      context.read<AppState>().updateDraft(widget.peerJid, controller.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().markRead(widget.peerJid);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    searchController.dispose();
    scroll.dispose();
    recordTimer?.cancel();
    micAmplitudeSub?.cancel();
    recorder.dispose();
    cameraController?.dispose();
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
          (message.attachmentName ?? '').toLowerCase().contains(q) ||
          (message.voicePath != null && 'голосовое сообщение'.contains(q)) ||
          (message.videoPath != null && 'видео кружок'.contains(q));
    }).toList();
    final allMessages = app.chatOf(widget.peerJid);
    final taskMessages =
        allMessages.where((message) => message.taskStatus != null).toList();
    final pinnedMessages =
        allMessages.where((message) => message.isPinned).toList();
    final pinnedQueue = pinnedMessages.reversed.toList();
    final currentPinnedMessage = pinnedQueue.isEmpty
        ? null
        : pinnedQueue[pinnedMessageCursor % pinnedQueue.length];
    final currentPinnedPosition = pinnedQueue.isEmpty
        ? 0
        : (pinnedMessageCursor % pinnedQueue.length) + 1;

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
                        color: cs.onSurface.withValues(alpha: 0.56),
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
                child:
                    Text('Очистить локальную историю'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
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
              if (taskMessages.isNotEmpty)
                _ChatTasksStrip(
                  messages: taskMessages,
                  onTap: () => _showChatTasks(context, taskMessages),
                ),
              if (currentPinnedMessage != null)
                _PinnedChatBar(
                  count: pinnedQueue.length,
                  position: currentPinnedPosition,
                  preview: _taskPreview(currentPinnedMessage),
                  onTap: () => _jumpToPinnedMessage(pinnedQueue),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final message = messages[i];
                    final messageKey = messageKeys.putIfAbsent(
                      message.id,
                      () => GlobalKey(),
                    );
                    return _Bubble(
                      key: messageKey,
                      message: message,
                      settings: settings,
                      onReply: () => setState(() {
                        replyToMessageId = message.id;
                        replyToText = _replyLabel(message);
                      }),
                      onReplyTap: message.replyToMessageId == null
                          ? null
                          : () => _jumpToMessage(message.replyToMessageId!),
                      onForward: () => _showForwardDialog(context, message),
                      onReact: (reaction) => app.setReaction(
                        widget.peerJid,
                        message.id,
                        reaction,
                      ),
                      onTaskStatus: (status) => app.setMessageTaskStatus(
                        widget.peerJid,
                        message.id,
                        status,
                      ),
                      onPinned: (pinned) => app.setMessagePinned(
                        widget.peerJid,
                        message.id,
                        pinned,
                      ),
                      favoriteReactions: app.favoriteReactions,
                      highlighted: highlightedMessageId == message.id,
                      onToggleFavoriteReaction: (emoji) {
                        unawaited(app.toggleFavoriteReaction(emoji));
                      },
                    );
                  },
                ),
              ),
              _Composer(
                controller: controller,
                replyToText: replyToText,
                onCancelReply: () => setState(() {
                  replyToMessageId = null;
                  replyToText = null;
                }),
                onSend: () => _sendText(context),
                onAttach: () => _showAttachmentPicker(context),
                isRecording: isRecording,
                isCaptureStarting: isCaptureStarting,
                isLocked: recordLocked,
                isCancelled: recordCancelled,
                lockProgress: lockDragProgress,
                captureMode: captureMode,
                activeCaptureMode: activeCaptureMode,
                recordDuration: recordDuration,
                cameraController: cameraController,
                onCaptureTap: _toggleCaptureMode,
                onCaptureHoldStart: () => _startCapture(context),
                onCaptureHoldMove: _handleCaptureMove,
                onCaptureHoldEnd: () => _finishCapture(context, fromHold: true),
                onRecordSend: () => _finishCapture(context, send: true),
                onRecordCancel: () => _finishCapture(context, send: false),
              ),
            ],
          ),
          if (isRecording && activeCaptureMode == _CaptureMode.video)
            _VideoRecordingOverlay(
              peerName: widget.peerName,
              cameraController: cameraController,
              duration: recordDuration,
              locked: recordLocked,
              cancelled: recordCancelled,
              screenFlashEnabled: screenFlashEnabled,
              flashEnabled:
                  _isFrontVideoCamera ? screenFlashEnabled : videoTorchEnabled,
              cameraSwitching: isSwitchingVideoCamera,
              flashChanging: isChangingVideoFlash,
              onCancel: () => _finishCapture(context, send: false),
              onSend: () => _finishCapture(context, send: true),
              onLock: _lockCapture,
              onSwitchCamera: _switchVideoCamera,
              onToggleFlash: _toggleVideoFlash,
              onZoomStart: _startVideoZoomGesture,
              onZoomUpdate: (details) {
                unawaited(_updateVideoZoomGesture(details));
              },
            ),
          if (isRecording && activeCaptureMode == _CaptureMode.voice)
            Positioned(
              right: 12,
              bottom: MediaQuery.of(context).padding.bottom + 72,
              child: _FloatingVideoButton(
                icon:
                    recordLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                selected: recordLocked,
                onTap: _lockCapture,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showChatTasks(
    BuildContext context,
    List<ChatMessage> taskMessages,
  ) async {
    MessageTaskStatus? selectedStatus;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final visible = selectedStatus == null
              ? taskMessages
              : taskMessages
                  .where((message) => message.taskStatus == selectedStatus)
                  .toList();

          return AlertDialog(
            title: const Text('Задачи в чате'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SmallActionChip(
                        label: 'Все',
                        selected: selectedStatus == null,
                        onTap: () => setDialogState(() {
                          selectedStatus = null;
                        }),
                      ),
                      for (final status in MessageTaskStatus.values)
                        _StatusActionChip(
                          status: status,
                          selected: selectedStatus == status,
                          onTap: () => setDialogState(() {
                            selectedStatus = status;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                          'Нет задач с выбранным статусом.'),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(height: 14),
                        itemBuilder: (_, index) {
                          final message = visible[index];
                          final status = message.taskStatus!;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TaskStatusDot(status: status),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      status.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _taskPreview(message),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Закрыть'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _jumpToPinnedMessage(List<ChatMessage> pinnedQueue) async {
    if (pinnedQueue.isEmpty) return;
    final index = pinnedMessageCursor % pinnedQueue.length;
    final message = pinnedQueue[index];
    await _jumpToMessage(message.id);
    if (!mounted) return;
    setState(() {
      pinnedMessageCursor = (index + 1) % pinnedQueue.length;
    });
  }

  String _taskPreview(ChatMessage message) {
    if (message.text.trim().isNotEmpty) return message.text.trim();
    if (message.attachmentName != null) return message.attachmentName!;
    if (message.voicePath != null) return 'Голосовое сообщение';
    if (message.videoPath != null) return 'Видео-кружок';
    return 'Сообщение';
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
    final replyId = replyToMessageId;
    final reply = replyToText;
    setState(() {
      replyToMessageId = null;
      replyToText = null;
    });
    await context.read<AppState>().sendText(
          widget.peerJid,
          text,
          replyToMessageId: replyId,
          replyToText: reply,
        );
    _scrollDown();
  }

  Future<void> _showAttachmentPicker(BuildContext context) async {
    final kind = await showDialog<_AttachmentKind>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Отправить'),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AttachmentAction(
                icon: Icons.image_rounded,
                label: 'Фото',
                color: cs.primary,
                onTap: () =>
                    Navigator.pop(dialogContext, _AttachmentKind.photo),
              ),
              _AttachmentAction(
                icon: Icons.movie_rounded,
                label: 'Видео',
                color: cs.secondary,
                onTap: () =>
                    Navigator.pop(dialogContext, _AttachmentKind.video),
              ),
              _AttachmentAction(
                icon: Icons.audiotrack_rounded,
                label: 'Аудио',
                color: cs.tertiary,
                onTap: () =>
                    Navigator.pop(dialogContext, _AttachmentKind.audio),
              ),
              _AttachmentAction(
                icon: Icons.attach_file_rounded,
                label: 'Файл',
                color: cs.onSurface,
                onTap: () => Navigator.pop(dialogContext, _AttachmentKind.file),
              ),
            ],
          ),
        );
      },
    );
    if (kind == null || !context.mounted) return;
    await _pickAndSendAttachment(context, kind);
  }

  Future<void> _pickAndSendAttachment(
    BuildContext context,
    _AttachmentKind kind,
  ) async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: _filePickerType(kind),
    );
    if (res == null || res.files.isEmpty) return;

    final caption = controller.text.trim();
    controller.clear();
    final replyId = replyToMessageId;
    final reply = replyToText;
    setState(() {
      replyToMessageId = null;
      replyToText = null;
    });

    var sent = 0;
    for (final file in res.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      await context.read<AppState>().sendAttachment(
            toJid: widget.peerJid,
            caption: sent == 0 ? caption : '',
            bytes: bytes,
            name: file.name,
            mime: _mimeFor(file.name, kind),
            replyToMessageId: sent == 0 ? replyId : null,
            replyToText: sent == 0 ? reply : null,
          );
      sent++;
    }
    _scrollDown();
  }

  FileType _filePickerType(_AttachmentKind kind) {
    return switch (kind) {
      _AttachmentKind.photo => FileType.image,
      _AttachmentKind.video => FileType.video,
      _AttachmentKind.audio => FileType.audio,
      _AttachmentKind.file => FileType.any,
    };
  }

  String _mimeFor(String name, _AttachmentKind kind) {
    final extension = name.split('.').last.toLowerCase();
    if (kind == _AttachmentKind.photo) return 'image/$extension';
    if (kind == _AttachmentKind.video) return 'video/$extension';
    if (kind == _AttachmentKind.audio) return 'audio/$extension';
    return switch (extension) {
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'zip' => 'application/zip',
      _ => 'application/octet-stream',
    };
  }

  void _toggleCaptureMode() {
    setState(() {
      captureMode = captureMode == _CaptureMode.voice
          ? _CaptureMode.video
          : _CaptureMode.voice;
    });
  }

  bool get _isFrontVideoCamera =>
      activeCameraDescription?.lensDirection == CameraLensDirection.front ||
      cameraController?.value.description.lensDirection ==
          CameraLensDirection.front;

  Future<void> _startCapture(BuildContext context) async {
    if (isRecording || isCaptureStarting || isCaptureFinishing) return;
    HapticFeedback.mediumImpact();
    isCaptureStarting = true;
    activeCaptureMode = captureMode;
    pendingCaptureSend = null;
    pendingCaptureFinishFromHold = false;
    setState(() {
      isRecording = true;
      recordLocked = false;
      recordCancelled = false;
      lockDragProgress = 0;
      recordDuration = Duration.zero;
      recordStartedAt = null;
      lastMicAmplitude = -160;
      if (activeCaptureMode == _CaptureMode.video) {
        videoSegments.clear();
        videoTorchEnabled = false;
        screenFlashEnabled = false;
        videoRecordedWithFrontCamera = false;
      }
    });

    try {
      if (activeCaptureMode == _CaptureMode.voice) {
        await _startVoiceRecording();
      } else {
        await _startVideoRecording();
      }

      recordStartedAt = DateTime.now();
      _startRecordTimer();
    } catch (e) {
      if (!mounted) return;
      await micAmplitudeSub?.cancel();
      micAmplitudeSub = null;
      if (activeCaptureMode == _CaptureMode.video && !keepVideoCameraAlive) {
        final controllerToDispose = cameraController;
        cameraController = null;
        await controllerToDispose?.dispose();
      }
      setState(() {
        isRecording = false;
        recordLocked = false;
        recordCancelled = false;
        lockDragProgress = 0;
        recordDuration = Duration.zero;
        recordStartedAt = null;
        videoTorchEnabled = false;
        screenFlashEnabled = false;
        isSwitchingVideoCamera = false;
        isChangingVideoFlash = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось начать запись: ${_errorText(e)}')),
      );
    } finally {
      isCaptureStarting = false;
      if (mounted) setState(() {});
      final pendingSend = pendingCaptureSend;
      final pendingFromHold = pendingCaptureFinishFromHold;
      pendingCaptureSend = null;
      pendingCaptureFinishFromHold = false;
      if (mounted && (pendingSend != null || pendingFromHold)) {
        unawaited(
          _finishCapture(
            context,
            send: pendingSend,
            fromHold: pendingFromHold,
          ),
        );
      }
    }
  }

  Future<void> _startVoiceRecording() async {
    await _ensureMicrophonePermission();

    await micAmplitudeSub?.cancel();
    micAmplitudeSub = null;

    final preferredMicrophoneId = context.read<AppState>().selectedMicrophoneId;
    final inputDevice = await _selectMicrophoneDevice(preferredMicrophoneId);
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.wav';
    await recorder.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
        device: inputDevice,
        autoGain: true,
        echoCancel: false,
        noiseSuppress: false,
      ),
      path: path,
    );

    micAmplitudeSub = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 250))
        .listen((amplitude) {
      if (amplitude.current > lastMicAmplitude) {
        lastMicAmplitude = amplitude.current;
      }
    });
  }

  Future<InputDevice?> _selectMicrophoneDevice(String? preferredId) async {
    final devices = await recorder.listInputDevices();
    if (devices.isEmpty) return null;

    final preferred = devices.where((device) => device.id == preferredId);
    if (preferred.isNotEmpty) return preferred.first;

    final filtered = devices.where((device) {
      final label = device.label.toLowerCase();
      return !label.contains('stereo mix') &&
          !label.contains('what u hear') &&
          !label.contains('output') &&
          !label.contains('speaker') &&
          !label.contains('динамик') &&
          !label.contains('выход');
    }).toList();

    return filtered.isNotEmpty ? filtered.first : devices.first;
  }

  Future<String?> _finishVoiceRecording() async {
    await micAmplitudeSub?.cancel();
    micAmplitudeSub = null;
    return recorder.stop();
  }

  Future<void> _startVideoRecording() async {
    await _ensureCameraAndMicrophonePermissions();

    CameraController? nextController;
    try {
      final existing = cameraController;
      if (existing != null && existing.value.isInitialized) {
        if (!existing.value.isRecordingVideo) {
          await existing.lockCaptureOrientation(DeviceOrientation.portraitUp);
          await existing.startVideoRecording();
        }
        activeCameraDescription = existing.value.description;
        videoRecordedWithFrontCamera = _isFrontVideoCamera;
        keepVideoCameraAlive = true;
        return;
      }

      final cameras = await availableCameras();
      videoCameras = cameras;
      if (cameras.isEmpty) {
        throw StateError('Камера недоступна');
      }
      final preferredCamera = activeCameraDescription;
      final camera = preferredCamera == null
          ? cameras.firstWhere(
              (item) => item.lensDirection == CameraLensDirection.front,
              orElse: () => cameras.first,
            )
          : cameras.firstWhere(
              (item) => item.name == preferredCamera.name,
              orElse: () => cameras.firstWhere(
                (item) => item.lensDirection == preferredCamera.lensDirection,
                orElse: () => cameras.first,
              ),
            );

      try {
        nextController = await _createStartedVideoController(
          camera: camera,
          enableAudio: true,
        );
      } on CameraException catch (e) {
        final description = e.description ?? '';
        final mediaTypeUnsupported = description.contains('носителя') ||
            description.toLowerCase().contains('media type');
        if (!mediaTypeUnsupported) rethrow;
        await nextController?.dispose();
        nextController = await _createStartedVideoController(
          camera: camera,
          enableAudio: false,
        );
      }
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      activeCameraDescription = camera;
      videoRecordedWithFrontCamera =
          camera.lensDirection == CameraLensDirection.front;
      keepVideoCameraAlive = true;
      setState(() => cameraController = nextController);
    } on MissingPluginException {
      await nextController?.dispose();
      throw StateError(
        'Камера не зарегистрирована. Полностью перезапустите приложение после обновления зависимостей.',
      );
    } catch (e) {
      await nextController?.dispose();
      if (e is CameraException &&
          e.description?.contains('already exists') == true) {
        final existing = cameraController;
        if (existing != null && existing.value.isInitialized) {
          await existing.lockCaptureOrientation(DeviceOrientation.portraitUp);
          await existing.startVideoRecording();
          activeCameraDescription = existing.value.description;
          videoRecordedWithFrontCamera = _isFrontVideoCamera;
          keepVideoCameraAlive = true;
          return;
        }
        throw StateError(
          'Камера занята предыдущей записью. Полностью закройте запущенное окно приложения и запустите заново.',
        );
      }
      rethrow;
    }
  }

  Future<CameraController> _createStartedVideoController({
    required CameraDescription camera,
    required bool enableAudio,
  }) async {
    final controller = await _createPreparedVideoController(
      camera: camera,
      enableAudio: enableAudio,
    );
    await controller.startVideoRecording();
    return controller;
  }

  Future<CameraController> _createPreparedVideoController({
    required CameraDescription camera,
    required bool enableAudio,
  }) async {
    final controller = CameraController(
      camera,
      _videoResolutionPreset(camera),
      enableAudio: enableAudio,
    );
    await controller.initialize();
    await controller.setFlashMode(FlashMode.off);
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await _configureVideoZoom(controller, reset: true);
    return controller;
  }

  ResolutionPreset _videoResolutionPreset(CameraDescription camera) {
    if (camera.lensDirection == CameraLensDirection.front) {
      return ResolutionPreset.high;
    }
    return ResolutionPreset.medium;
  }

  Future<void> _configureVideoZoom(
    CameraController controller, {
    required bool reset,
  }) async {
    try {
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      final nextZoom = reset
          ? minZoom
          : videoZoomLevel.clamp(minZoom, maxZoom).toDouble();
      await controller.setZoomLevel(nextZoom);
      videoMinZoomLevel = minZoom;
      videoMaxZoomLevel = maxZoom;
      videoZoomLevel = nextZoom;
      videoZoomLevelOnGestureStart = nextZoom;
    } catch (_) {
      videoMinZoomLevel = 1;
      videoMaxZoomLevel = 1;
      videoZoomLevel = 1;
      videoZoomLevelOnGestureStart = 1;
    }
  }

  Future<CameraController> _createPreparedVideoControllerWithAudioFallback(
    CameraDescription camera,
  ) async {
    CameraController? nextController;
    try {
      nextController = await _createPreparedVideoController(
        camera: camera,
        enableAudio: true,
      );
      return nextController;
    } on CameraException catch (e) {
      final description = e.description ?? '';
      final mediaTypeUnsupported = description.contains('носителя') ||
          description.toLowerCase().contains('media type');
      if (!mediaTypeUnsupported) rethrow;
      await nextController?.dispose();
      return _createPreparedVideoController(
        camera: camera,
        enableAudio: false,
      );
    }
  }

  Future<void> _switchVideoCamera() async {
    final controller = cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        isSwitchingVideoCamera ||
        isCaptureFinishing) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => isSwitchingVideoCamera = true);
    CameraController? nextController;
    try {
      var cameras = videoCameras;
      if (cameras.isEmpty) {
        cameras = await availableCameras();
        videoCameras = cameras;
      }
      if (cameras.length < 2) return;

      await _disableVideoFlash(controller);

      final current = activeCameraDescription ?? controller.value.description;
      final differentDirection = cameras.where(
        (item) => item.lensDirection != current.lensDirection,
      );
      final next = differentDirection.isNotEmpty
          ? differentDirection.first
          : cameras[
              (cameras.indexWhere((item) => item.name == current.name) + 1) %
                  cameras.length];

      if (controller.value.isRecordingVideo) {
        final segmentWasFrontCamera = _isFrontVideoCamera;
        final file = await controller.stopVideoRecording();
        videoSegments.add(
          _VideoSegment(
            path: file.path,
            mirrorHorizontally: segmentWasFrontCamera,
          ),
        );
      }
      await controller.dispose();
      if (!mounted) return;

      if (cameraController == controller) {
        setState(() => cameraController = null);
      }

      // CameraX on Android can report CameraUnavailable or device frame errors
      // if a second camera is initialized before the previous session is fully
      // torn down. Give the platform one frame after dispose before opening.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      nextController = await _createPreparedVideoControllerWithAudioFallback(
        next,
      );
      if (!nextController.value.isRecordingVideo) {
        await nextController.startVideoRecording();
      }
      if (!mounted) {
        await nextController.dispose();
        return;
      }
      activeCameraDescription = next;
      videoRecordedWithFrontCamera =
          next.lensDirection == CameraLensDirection.front;
      keepVideoCameraAlive = true;
      setState(() {
        cameraController = nextController;
        videoTorchEnabled = false;
        screenFlashEnabled = false;
      });
    } catch (e) {
      await nextController?.dispose();
      if (mounted) {
        _showLocalHint(
            context, 'Не удалось переключить камеру: ${_errorText(e)}');
      }
    } finally {
      if (mounted) setState(() => isSwitchingVideoCamera = false);
    }
  }

  Future<void> _toggleVideoFlash() async {
    final controller = cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        isChangingVideoFlash ||
        isCaptureFinishing) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => isChangingVideoFlash = true);
    try {
      if (_isFrontVideoCamera) {
        setState(() {
          screenFlashEnabled = !screenFlashEnabled;
          videoTorchEnabled = false;
        });
        return;
      }

      final enable = !videoTorchEnabled;
      await controller.setFlashMode(enable ? FlashMode.torch : FlashMode.off);
      setState(() {
        videoTorchEnabled = enable;
        screenFlashEnabled = false;
      });
    } catch (e) {
      if (mounted) {
        _showLocalHint(
            context, 'Не удалось переключить вспышку: ${_errorText(e)}');
      }
    } finally {
      if (mounted) setState(() => isChangingVideoFlash = false);
    }
  }

  void _startVideoZoomGesture(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    videoZoomLevelOnGestureStart = videoZoomLevel;
  }

  Future<void> _updateVideoZoomGesture(ScaleUpdateDetails details) async {
    if (details.pointerCount < 2) return;
    final controller = cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        isSwitchingVideoCamera ||
        isCaptureFinishing) {
      return;
    }

    final nextZoom = (videoZoomLevelOnGestureStart * details.scale)
        .clamp(videoMinZoomLevel, videoMaxZoomLevel)
        .toDouble();
    if ((nextZoom - videoZoomLevel).abs() < 0.02) return;

    videoZoomLevel = nextZoom;
    try {
      await controller.setZoomLevel(nextZoom);
    } catch (_) {}
  }

  Future<void> _disableVideoFlash(CameraController controller) async {
    if (videoTorchEnabled) {
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        videoTorchEnabled = false;
        screenFlashEnabled = false;
      });
    } else {
      videoTorchEnabled = false;
      screenFlashEnabled = false;
    }
  }

  Future<void> _ensureMicrophonePermission() async {
    final mic = await _requestPermission(
      Permission.microphone,
      deniedMessage: 'Нет доступа к микрофону',
      permanentlyDeniedMessage:
          'Доступ к микрофону запрещен в настройках приложения',
    );
    if (!mic) {
      throw StateError('нет доступа к микрофону');
    }

    final recorderAllowed = await recorder.hasPermission();
    if (!recorderAllowed) {
      throw StateError('нет доступа к микрофону');
    }
  }

  Future<void> _ensureCameraAndMicrophonePermissions() async {
    final camera = await _requestPermission(
      Permission.camera,
      deniedMessage: 'Нет доступа к камере',
      permanentlyDeniedMessage:
          'Доступ к камере запрещен в настройках приложения',
    );
    if (!camera) {
      throw StateError('нет доступа к камере');
    }
    await _ensureMicrophonePermission();
  }

  Future<bool> _requestPermission(
    Permission permission, {
    required String deniedMessage,
    required String permanentlyDeniedMessage,
  }) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied || status.isRestricted) {
      throw StateError(permanentlyDeniedMessage);
    }
    throw StateError(deniedMessage);
  }

  void _startRecordTimer() {
    recordTimer?.cancel();
    recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        recordDuration += const Duration(seconds: 1);
      });
    });
  }

  String _errorText(Object error) {
    final text = error.toString();
    const badStatePrefix = 'Bad state: ';
    if (text.startsWith(badStatePrefix)) {
      return text.substring(badStatePrefix.length);
    }
    const exceptionPrefix = 'Exception: ';
    if (text.startsWith(exceptionPrefix)) {
      return text.substring(exceptionPrefix.length);
    }
    return text;
  }

  void _handleCaptureMove(LongPressMoveUpdateDetails details) {
    if (!isRecording || recordLocked) return;
    final offset = details.offsetFromOrigin;
    final nextLockProgress = (-offset.dy / 92).clamp(0.0, 1.0);
    final nextLocked = nextLockProgress >= 1;
    final nextCancelled = offset.dx < -92;
    if (nextLocked && !recordLocked) {
      HapticFeedback.mediumImpact();
    } else if (nextCancelled != recordCancelled) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      if (nextLocked) recordLocked = true;
      lockDragProgress = nextLocked ? 1 : nextLockProgress;
      recordCancelled = nextCancelled;
    });
  }

  void _lockCapture() {
    if (!isRecording || recordLocked) return;
    HapticFeedback.mediumImpact();
    setState(() {
      recordLocked = true;
      lockDragProgress = 1;
      recordCancelled = false;
    });
  }

  Future<void> _finishCapture(
    BuildContext context, {
    bool? send,
    bool fromHold = false,
  }) async {
    if (!isRecording || isCaptureFinishing) return;
    if (isCaptureStarting) {
      pendingCaptureSend = send;
      pendingCaptureFinishFromHold = fromHold;
      return;
    }
    if (fromHold && recordLocked) return;
    HapticFeedback.lightImpact();
    isCaptureFinishing = true;

    final shouldSend = send ?? !recordCancelled;
    final mode = activeCaptureMode;
    final startedAt = recordStartedAt;
    final duration = startedAt == null
        ? recordDuration
        : DateTime.now().difference(startedAt);

    recordTimer?.cancel();
    recordTimer = null;

    String? path;
    String? pendingMessageId;
    var mirrorVideoHorizontally =
        mode == _CaptureMode.video && videoRecordedWithFrontCamera;
    final app = context.read<AppState>();
    final replyId = replyToMessageId;
    final reply = replyToText;
    final shouldCreatePending = shouldSend && duration.inMilliseconds >= 500;

    if (mounted) {
      setState(() {
        isRecording = false;
        recordLocked = false;
        recordCancelled = false;
        lockDragProgress = 0;
        recordDuration = Duration.zero;
        recordStartedAt = null;
        screenFlashEnabled = false;
      });
    }

    if (shouldCreatePending) {
      pendingMessageId = app.addPendingMediaMessage(
        peerKey: widget.peerJid,
        kind: mode == _CaptureMode.voice
            ? ChatMediaKind.voice
            : ChatMediaKind.videoCircle,
        duration: duration,
        replyToMessageId: replyId,
        replyToText: reply,
      );
      if (mounted) {
        setState(() {
          replyToMessageId = null;
          replyToText = null;
        });
      }
      _scrollDown();
    }

    try {
      if (mode == _CaptureMode.voice) {
        if (pendingMessageId != null) {
          app.updateMediaProgress(
            widget.peerJid,
            pendingMessageId,
            progress: 0.18,
            status: 'сохранение',
          );
        }
        path = await _finishVoiceRecording();
        if (pendingMessageId != null) {
          app.updateMediaProgress(
            widget.peerJid,
            pendingMessageId,
            progress: 0.76,
            status: 'подготовка',
          );
        }
      } else {
        final activeCamera = cameraController;
        if (activeCamera != null && activeCamera.value.isRecordingVideo) {
          if (videoTorchEnabled) {
            try {
              await activeCamera.setFlashMode(FlashMode.off);
            } catch (_) {}
          }
          final file = await activeCamera.stopVideoRecording();
          if (pendingMessageId != null) {
            app.updateMediaProgress(
              widget.peerJid,
              pendingMessageId,
              progress: 0.32,
              status: 'сохранение',
            );
          }
          videoSegments.add(
            _VideoSegment(
              path: file.path,
              mirrorHorizontally: _isFrontVideoCamera,
            ),
          );
          cameraController = null;
          keepVideoCameraAlive = false;
          videoTorchEnabled = false;
          await activeCamera.dispose();
          if (videoSegments.length == 1) {
            path = videoSegments.first.path;
            mirrorVideoHorizontally = videoSegments.first.mirrorHorizontally;
            if (pendingMessageId != null) {
              app.updateMediaProgress(
                widget.peerJid,
                pendingMessageId,
                progress: 0.86,
                status: 'подготовка',
              );
            }
          } else {
            path = await _mergeVideoSegments(
              videoSegments,
              duration: duration,
              onProgress: pendingMessageId == null
                  ? null
                  : (progress) {
                      app.updateMediaProgress(
                        widget.peerJid,
                        pendingMessageId!,
                        progress: progress,
                        status: 'склейка',
                      );
                    },
            );
            mirrorVideoHorizontally = false;
          }
        }
      }
    } catch (e) {
      if (pendingMessageId != null) {
        app.failMediaMessage(widget.peerJid, pendingMessageId, 'ошибка');
      }
      if (mode == _CaptureMode.video) {
        await _deleteVideoRecordingFiles(null, videoSegments);
        if (mounted) {
          _showLocalHint(
            context,
            'Не удалось сохранить видеокружок: ${_errorText(e)}',
          );
        }
      }
      path = null;
    }

    if (!mounted) {
      isCaptureFinishing = false;
      return;
    }
    setState(() {
      isRecording = false;
      recordLocked = false;
      recordCancelled = false;
      lockDragProgress = 0;
      recordDuration = Duration.zero;
      recordStartedAt = null;
      videoTorchEnabled = false;
      screenFlashEnabled = false;
      isSwitchingVideoCamera = false;
      isChangingVideoFlash = false;
    });

    try {
      if (path == null) {
        if (pendingMessageId != null) {
          app.failMediaMessage(widget.peerJid, pendingMessageId, 'ошибка');
        }
        return;
      }
      if (!shouldSend || duration.inMilliseconds < 500) {
        await _deleteVideoRecordingFiles(path, videoSegments);
        return;
      }

      pendingMessageId ??= app.addPendingMediaMessage(
        peerKey: widget.peerJid,
        kind: mode == _CaptureMode.voice
            ? ChatMediaKind.voice
            : ChatMediaKind.videoCircle,
        duration: duration,
        replyToMessageId: replyId,
        replyToText: reply,
      );
      if (mode == _CaptureMode.voice) {
        await app.completePendingVoiceMessage(
          peerKey: widget.peerJid,
          messageId: pendingMessageId!,
          path: path,
          duration: duration,
        );
      } else {
        await app.completePendingVideoCircleMessage(
          peerKey: widget.peerJid,
          messageId: pendingMessageId!,
          path: path,
          duration: duration,
          mirrorHorizontally: mirrorVideoHorizontally,
        );
      }
      _scrollDown();
    } catch (e) {
      if (pendingMessageId != null) {
        app.failMediaMessage(widget.peerJid, pendingMessageId, 'ошибка');
      }
    } finally {
      final firstSegmentPath =
          videoSegments.isEmpty ? null : videoSegments.first.path;
      if (mode == _CaptureMode.video &&
          path != null &&
          path != firstSegmentPath) {
        await _deleteVideoRecordingFiles(null, videoSegments);
      }
      videoSegments.clear();
      isCaptureFinishing = false;
    }
  }

  Future<String> _mergeVideoSegments(
    List<_VideoSegment> segments, {
    required Duration duration,
    ValueChanged<double>? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final output =
        '${dir.path}/video_circle_${DateTime.now().microsecondsSinceEpoch}.mp4';

    final inputs = segments.map((segment) => '-i ${_ffmpegArg(segment.path)}');
    final filters = <String>[];
    final concatInputs = <String>[];
    for (var i = 0; i < segments.length; i++) {
      final mirror = segments[i].mirrorHorizontally ? 'hflip,' : '';
      filters.add(
        '[$i:v]$mirror'
        'scale=480:480:force_original_aspect_ratio=increase,'
        'crop=480:480,setsar=1,fps=30,format=yuv420p[v$i]',
      );
      filters.add(
        '[$i:a]aformat=sample_fmts=fltp:sample_rates=44100:'
        'channel_layouts=mono[a$i]',
      );
      concatInputs.add('[v$i][a$i]');
    }
    filters.add(
      '${concatInputs.join()}concat=n=${segments.length}:v=1:a=1[v][a]',
    );

    final command = [
      '-y',
      ...inputs,
      '-filter_complex',
      _ffmpegArg(filters.join(';')),
      '-map',
      _ffmpegArg('[v]'),
      '-map',
      _ffmpegArg('[a]'),
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-crf',
      '24',
      '-c:a',
      'aac',
      '-b:a',
      '96k',
      '-movflags',
      '+faststart',
      _ffmpegArg(output),
    ].join(' ');

    final completer = Completer<void>();
    final totalMs = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;
    late final dynamic session;
    session = await FFmpegKit.executeAsync(
      command,
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
      null,
      (Statistics statistics) {
        final progress = (statistics.getTime() / totalMs).clamp(0.0, 1.0);
        onProgress?.call(0.34 + progress * 0.52);
      },
    );
    await completer.future;
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw StateError('Не удалось склеить видеокружок: $logs');
    }
    return output;
  }

  Future<void> _deleteVideoRecordingFiles(
    String? outputPath,
    List<_VideoSegment> segments,
  ) async {
    final paths = <String>{
      if (outputPath != null) outputPath,
      ...segments.map((segment) => segment.path),
    };
    for (final path in paths) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  String _ffmpegArg(String value) {
    return "'${value.replaceAll("'", r"'\''")}'";
  }

  String _replyLabel(ChatMessage message) {
    if (message.text.isNotEmpty) return message.text;
    if (message.voicePath != null) return 'Голосовое сообщение';
    if (message.videoPath != null) return 'Видео-кружок';
    return message.attachmentName ?? 'Вложение';
  }

  Future<void> _jumpToMessage(String messageId) async {
    final allMessages = context.read<AppState>().chatOf(widget.peerJid);
    final index = allMessages.indexWhere((message) => message.id == messageId);
    if (index == -1) {
      _showLocalHint(
          context, 'Исходное сообщение не найдено');
      return;
    }

    if (searchMode) {
      setState(() {
        searchMode = false;
        searchController.clear();
      });
      await WidgetsBinding.instance.endOfFrame;
    }

    final targetContext = messageKeys[messageId]?.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 240),
        alignment: 0.42,
      );
    } else if (scroll.hasClients) {
      final maxOffset = scroll.position.maxScrollExtent;
      final estimatedOffset = (index * 92.0).clamp(0.0, maxOffset);
      await scroll.animateTo(
        estimatedOffset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      await WidgetsBinding.instance.endOfFrame;
      final builtContext = messageKeys[messageId]?.currentContext;
      if (builtContext != null) {
        await Scrollable.ensureVisible(
          builtContext,
          duration: const Duration(milliseconds: 180),
          alignment: 0.42,
        );
      }
    }

    if (!mounted) return;
    setState(() => highlightedMessageId = messageId);
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted && highlightedMessageId == messageId) {
        setState(() => highlightedMessageId = null);
      }
    });
  }

  Future<void> _showForwardDialog(
    BuildContext context,
    ChatMessage message,
  ) async {
    final app = context.read<AppState>();
    final targets = [
      for (final contact in app.visibleContacts(includeArchived: true))
        _ForwardTarget(
          peerKey: contact.jid,
          title: contact.displayName,
          subtitle: contact.jid,
        ),
      for (final group in app.groups)
        _ForwardTarget(
          peerKey: app.groupPeerKey(group.id),
          title: group.name,
          subtitle: 'Группа',
        ),
    ];

    final target = await showDialog<_ForwardTarget>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Переслать'),
        content: SizedBox(
          width: 420,
          height: 420,
          child: targets.isEmpty
              ? const Center(
                  child: Text('Нет доступных чатов'))
              : ListView.separated(
                  itemCount: targets.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final target = targets[index];
                    final isGroup = target.peerKey.startsWith('group:');
                    return ListTile(
                      leading: Icon(
                        isGroup ? Icons.groups_rounded : Icons.person_rounded,
                      ),
                      title: Text(
                        target.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        target.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(dialogContext, target),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
    if (!context.mounted || target == null) return;

    await app.forwardMessage(
      toPeerKey: target.peerKey,
      source: message,
      forwardedFrom: message.isMe ? app.profile.name : widget.peerName,
    );
    if (context.mounted) {
      _showLocalHint(context, 'Переслано в ${target.title}');
    }
  }

  void _showLocalHint(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _confirmClearChat(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Очистить историю?'),
        content: const Text(
          'Сообщения будут удалены только локально.',
        ),
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

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String? replyToText;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool isRecording;
  final bool isCaptureStarting;
  final bool isLocked;
  final bool isCancelled;
  final double lockProgress;
  final _CaptureMode captureMode;
  final _CaptureMode activeCaptureMode;
  final Duration recordDuration;
  final CameraController? cameraController;
  final VoidCallback onCaptureTap;
  final VoidCallback onCaptureHoldStart;
  final ValueChanged<LongPressMoveUpdateDetails> onCaptureHoldMove;
  final VoidCallback onCaptureHoldEnd;
  final VoidCallback onRecordSend;
  final VoidCallback onRecordCancel;

  const _Composer({
    required this.controller,
    required this.replyToText,
    required this.onCancelReply,
    required this.onSend,
    required this.onAttach,
    required this.isRecording,
    required this.isCaptureStarting,
    required this.isLocked,
    required this.isCancelled,
    required this.lockProgress,
    required this.captureMode,
    required this.activeCaptureMode,
    required this.recordDuration,
    required this.cameraController,
    required this.onCaptureTap,
    required this.onCaptureHoldStart,
    required this.onCaptureHoldMove,
    required this.onCaptureHoldEnd,
    required this.onRecordSend,
    required this.onRecordCancel,
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
                      .withValues(alpha: 0.4),
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
                if (!isRecording)
                  IconButton(
                    tooltip: 'Прикрепить',
                    onPressed: onAttach,
                    icon: const Icon(Icons.attach_file),
                  ),
                Expanded(
                  child: isRecording
                      ? _RecordingBar(
                          mode: activeCaptureMode,
                          duration: recordDuration,
                          locked: isLocked,
                          cancelled: isCancelled,
                          cameraController: cameraController,
                        )
                      : SizedBox(
                          height: 44,
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => onSend(),
                            decoration: const InputDecoration(
                              hintText: 'Сообщение...',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final hasText = controller.text.trim().isNotEmpty;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRecording) ...[
                          TextButton(
                            onPressed: onRecordCancel,
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text(
                              'Отмена',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        _CaptureButton(
                          hasText: hasText,
                          mode: captureMode,
                          recording: isRecording,
                          starting: isCaptureStarting,
                          locked: isLocked,
                          cancelled: isCancelled,
                          lockProgress: lockProgress,
                          onSendText: onSend,
                          onTapMode: onCaptureTap,
                          onHoldStart: onCaptureHoldStart,
                          onHoldMove: onCaptureHoldMove,
                          onHoldEnd: onCaptureHoldEnd,
                          onSendRecording: onRecordSend,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  final _CaptureMode mode;
  final Duration duration;
  final bool locked;
  final bool cancelled;
  final CameraController? cameraController;

  const _RecordingBar({
    required this.mode,
    required this.duration,
    required this.locked,
    required this.cancelled,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (mode == _CaptureMode.voice) {
      return _VoiceRecordingPanel(
        duration: duration,
        locked: locked,
        cancelled: cancelled,
      );
    }
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _RecordingPreview(mode: mode, cameraController: cameraController),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cancelled ? 'Отпустите, чтобы удалить' : ' ',
                  style: TextStyle(
                    color: cancelled ? cs.error : cs.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locked
                      ? 'Запись закреплена'
                      : 'Вверх - закрепить, влево - удалить',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.56),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceRecordingPanel extends StatelessWidget {
  final Duration duration;
  final bool locked;
  final bool cancelled;

  const _VoiceRecordingPanel({
    required this.duration,
    required this.locked,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = cancelled ? cs.error : cs.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Color.lerp(cs.surface, cs.surfaceContainerHighest, 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (locked ? cs.primary : cs.onSurface).withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: Icon(
              cancelled
                  ? Icons.close_rounded
                  : Icons.fiber_manual_record_rounded,
              key: ValueKey(cancelled),
              color: cs.error,
              size: cancelled ? 18 : 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatCaptureDuration(duration),
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RecordingWaveform(
              duration: duration,
              color: accent,
              muted: locked,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingWaveform extends StatelessWidget {
  final Duration duration;
  final Color color;
  final bool muted;

  const _RecordingWaveform({
    required this.duration,
    required this.color,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final phase = duration.inMilliseconds / 220;
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(24, (index) {
          final t = (index + phase) % 8;
          final wave = t < 4 ? t / 4 : (8 - t) / 4;
          final height = muted ? 7.0 : 6.0 + (18 * wave);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: color.withValues(alpha: muted ? 0.34 : 0.82),
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }
}

String _formatCaptureDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString();
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _RecordingPreview extends StatelessWidget {
  final _CaptureMode mode;
  final CameraController? cameraController;

  const _RecordingPreview({
    required this.mode,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (mode == _CaptureMode.voice) {
      return Icon(Icons.mic_rounded, color: cs.error);
    }
    final controller = cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Icon(Icons.videocam_rounded, color: cs.error);
    }
    return ClipOval(
      child: SizedBox(
        width: 38,
        height: 38,
        child: _StableCameraPreview(
          controller: controller,
          fallbackSize: 38,
        ),
      ),
    );
  }
}

class _StableCameraPreview extends StatelessWidget {
  final CameraController controller;
  final double fallbackSize;

  const _StableCameraPreview({
    required this.controller,
    required this.fallbackSize,
  });

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size?.height ?? fallbackSize,
        height: size?.width ?? fallbackSize,
        child: RepaintBoundary(child: controller.buildPreview()),
      ),
    );
  }
}

class _VideoRecordingOverlay extends StatelessWidget {
  final String peerName;
  final CameraController? cameraController;
  final Duration duration;
  final bool locked;
  final bool cancelled;
  final bool screenFlashEnabled;
  final bool flashEnabled;
  final bool cameraSwitching;
  final bool flashChanging;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final VoidCallback onLock;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleFlash;
  final GestureScaleStartCallback onZoomStart;
  final GestureScaleUpdateCallback onZoomUpdate;

  const _VideoRecordingOverlay({
    required this.peerName,
    required this.cameraController,
    required this.duration,
    required this.locked,
    required this.cancelled,
    required this.screenFlashEnabled,
    required this.flashEnabled,
    required this.cameraSwitching,
    required this.flashChanging,
    required this.onCancel,
    required this.onSend,
    required this.onLock,
    required this.onSwitchCamera,
    required this.onToggleFlash,
    required this.onZoomStart,
    required this.onZoomUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 180),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withValues(alpha: 0.48),
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: screenFlashEnabled ? 0.72 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _VideoTopBar(peerName: peerName),
                    ),
                  ),
                  Center(
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: _VideoProgressRing(
                        duration: duration,
                        color: cancelled ? cs.error : cs.primary,
                        child: _VideoPreviewCircle(
                          controller: cameraController,
                          onZoomStart: onZoomStart,
                          onZoomUpdate: onZoomUpdate,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 104,
                    child: Column(
                      children: [
                        _FloatingVideoButton(
                          icon: locked
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          selected: locked,
                          onTap: onLock,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 104,
                    child: Row(
                      children: [
                        _FloatingVideoButton(
                          icon: Icons.cameraswitch_rounded,
                          onTap: cameraSwitching ? null : onSwitchCamera,
                        ),
                        const SizedBox(width: 12),
                        _FloatingVideoButton(
                          icon: flashEnabled
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          selected: flashEnabled,
                          onTap: flashChanging ? null : onToggleFlash,
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _formatCaptureDuration(duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: onCancel,
                              child: const Text(
                                'Отмена',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _RecordingControlButton(
                              icon: Icons.send_rounded,
                              onTap: onSend,
                              color: cs.primary,
                              filled: true,
                            ),
                          ],
                        ),
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

class _RecordingControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool filled;

  const _RecordingControlButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.white.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: filled ? 58 : 46,
          height: filled ? 58 : 46,
          child: Icon(
            icon,
            color: Colors.white,
            size: filled ? 28 : 22,
          ),
        ),
      ),
    );
  }
}

class _FloatingVideoButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;

  const _FloatingVideoButton({
    required this.icon,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.86)
          : Colors.black.withValues(alpha: 0.36),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _VideoTopBar extends StatelessWidget {
  final String peerName;

  const _VideoTopBar({required this.peerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              peerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoProgressRing extends StatelessWidget {
  final Duration duration;
  final Color color;
  final Widget child;

  const _VideoProgressRing({
    required this.duration,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (duration.inMilliseconds % 60000) / 60000;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 276,
          height: 276,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.14),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        child,
      ],
    );
  }
}

class _VideoPreviewCircle extends StatelessWidget {
  final CameraController? controller;
  final GestureScaleStartCallback onZoomStart;
  final GestureScaleUpdateCallback onZoomUpdate;

  const _VideoPreviewCircle({
    required this.controller,
    required this.onZoomStart,
    required this.onZoomUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onScaleStart: onZoomStart,
      onScaleUpdate: onZoomUpdate,
      child: Container(
        width: 252,
        height: 252,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: controller != null && controller!.value.isInitialized
            ? _StableCameraPreview(
                controller: controller!,
                fallbackSize: 252,
              )
            : Center(
                child: Icon(
                  Icons.videocam_rounded,
                  size: 42,
                  color: Colors.white.withValues(alpha: 0.58),
                ),
              ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool hasText;
  final _CaptureMode mode;
  final bool recording;
  final bool starting;
  final bool locked;
  final bool cancelled;
  final double lockProgress;
  final VoidCallback onSendText;
  final VoidCallback onTapMode;
  final VoidCallback onHoldStart;
  final ValueChanged<LongPressMoveUpdateDetails> onHoldMove;
  final VoidCallback onHoldEnd;
  final VoidCallback onSendRecording;

  const _CaptureButton({
    required this.hasText,
    required this.mode,
    required this.recording,
    required this.starting,
    required this.locked,
    required this.cancelled,
    required this.lockProgress,
    required this.onSendText,
    required this.onTapMode,
    required this.onHoldStart,
    required this.onHoldMove,
    required this.onHoldEnd,
    required this.onSendRecording,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = hasText
        ? Icons.send
        : starting
            ? Icons.more_horiz_rounded
            : recording
                ? Icons.send_rounded
                : mode == _CaptureMode.voice
                    ? Icons.mic_rounded
                    : Icons.videocam_rounded;
    final tooltip = hasText
        ? 'Отправить'
        : recording && locked
            ? 'Отправить запись'
            : mode == _CaptureMode.voice
                ? 'Голосовое сообщение'
                : 'Видео-кружок';

    final active = recording || starting;
    final background = cancelled
        ? cs.error
        : active
            ? Color.lerp(cs.primary, cs.error, 0.28)!
            : cs.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        if (hasText) {
          onSendText();
        } else if (recording) {
          onSendRecording();
        } else if (!recording && !starting) {
          onTapMode();
        }
      },
      onLongPressStart: hasText || recording ? null : (_) => onHoldStart(),
      onLongPressMoveUpdate: hasText ? null : onHoldMove,
      onLongPressEnd: hasText ? null : (_) => onHoldEnd(),
      child: SizedBox(
        width: 54,
        height: 54,
        child: Semantics(
          label: tooltip,
          button: true,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            scale: active ? 1.04 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(active ? 16 : 14),
                boxShadow: [
                  if (active)
                    BoxShadow(
                      color: background.withValues(alpha: 0.34),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (starting)
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          cs.onPrimary.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  Icon(
                    icon,
                    color: cs.onPrimary.withValues(alpha: starting ? 0 : 1),
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

class _ChatTasksStrip extends StatelessWidget {
  final List<ChatMessage> messages;
  final VoidCallback onTap;

  const _ChatTasksStrip({
    required this.messages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeCount = messages
        .where((message) =>
            message.taskStatus != null &&
            message.taskStatus != MessageTaskStatus.done)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.task_alt_rounded, size: 15, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Задачи: $activeCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinnedChatBar extends StatelessWidget {
  final int count;
  final int position;
  final String preview;
  final VoidCallback onTap;

  const _PinnedChatBar({
    required this.count,
    required this.position,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 30,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 9),
              Icon(Icons.push_pin_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? 'Закрепленное сообщение'
                          : 'Закреплено: $position из $count',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.62),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskStatusBadge extends StatelessWidget {
  final MessageTaskStatus status;

  const _TaskStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _taskStatusColor(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TaskStatusDot(status: status),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedMessageBadge extends StatelessWidget {
  const _PinnedMessageBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin_rounded,
              size: 13,
              color: cs.onSurface.withValues(alpha: 0.72),
            ),
            const SizedBox(width: 5),
            Text(
              'Закреплено',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskStatusDot extends StatelessWidget {
  final MessageTaskStatus status;

  const _TaskStatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _taskStatusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatusActionChip extends StatelessWidget {
  final MessageTaskStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _StatusActionChip({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _taskStatusColor(status);
    return _SmallActionChip(
      label: status.label,
      selected: selected,
      color: color,
      leading: _TaskStatusDot(status: status),
      onTap: onTap,
    );
  }
}

class _SmallActionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final Widget? leading;
  final VoidCallback onTap;

  const _SmallActionChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.color,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : cs.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? accent : cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiReactionButton extends StatelessWidget {
  final String emoji;
  final bool selected;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EmojiReactionButton({
    required this.emoji,
    required this.selected,
    required this.favorite,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: favorite
          ? 'В избранном. Долгое нажатие уберет'
          : 'Долгое нажатие добавит в избранное',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.16)
                : cs.surfaceContainerHighest.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 21)),
              if (favorite)
                Positioned(
                  right: 3,
                  top: 3,
                  child: Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: cs.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconTextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

Color _taskStatusColor(MessageTaskStatus status) {
  return switch (status) {
    MessageTaskStatus.newItem => const Color(0xFFB8B2A8),
    MessageTaskStatus.inProgress => const Color(0xFFC39A54),
    MessageTaskStatus.waiting => const Color(0xFF8F8678),
    MessageTaskStatus.done => const Color(0xFF6F9A79),
    MessageTaskStatus.rejected => const Color(0xFFC76666),
  };
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final MessageDisplaySettings settings;
  final VoidCallback onReply;
  final VoidCallback? onReplyTap;
  final Future<void> Function() onForward;
  final ValueChanged<String?> onReact;
  final ValueChanged<MessageTaskStatus?> onTaskStatus;
  final ValueChanged<bool> onPinned;
  final Set<String> favoriteReactions;
  final bool highlighted;
  final ValueChanged<String> onToggleFavoriteReaction;

  const _Bubble({
    super.key,
    required this.message,
    required this.settings,
    required this.onReply,
    required this.onReplyTap,
    required this.onForward,
    required this.onReact,
    required this.onTaskStatus,
    required this.onPinned,
    required this.favoriteReactions,
    required this.highlighted,
    required this.onToggleFavoriteReaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMe = message.isMe;
    final isVideoCircle = message.videoPath != null ||
        message.mediaKind == ChatMediaKind.videoCircle;
    final mediaProgress = message.mediaProgress;
    final statusColor = message.taskStatus == null
        ? null
        : _taskStatusColor(message.taskStatus!);
    final bubbleColor = statusColor == null
        ? (isMe ? cs.primary.withValues(alpha: 0.16) : cs.surface)
        : Color.lerp(cs.surface, statusColor, isMe ? 0.18 : 0.12)!;
    final resolvedBubbleColor =
        highlighted ? Color.lerp(bubbleColor, cs.primary, 0.20)! : bubbleColor;
    final bubbleBorder = statusColor == null
        ? (isMe ? cs.primary.withValues(alpha: 0.42) : Colors.transparent)
        : statusColor.withValues(alpha: 0.44);
    final resolvedBubbleBorder =
        highlighted ? cs.primary.withValues(alpha: 0.72) : bubbleBorder;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: settings.messageSpacing),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _showQuickMessageMenu(context),
              onLongPress: () => _showQuickMessageMenu(context),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: isVideoCircle
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(
                        horizontal: settings.horizontalMessagePadding,
                        vertical: settings.verticalMessagePadding,
                      ),
                decoration: isVideoCircle
                    ? null
                    : BoxDecoration(
                        color: resolvedBubbleColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: resolvedBubbleBorder),
                      ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.forwardedFrom != null) ...[
                      _ForwardedBadge(from: message.forwardedFrom!),
                      const SizedBox(height: 8),
                    ],
                    if (message.replyToText != null) ...[
                      _ReplyPreview(
                        text: message.replyToText!,
                        onTap: onReplyTap,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (message.attachmentBytes != null &&
                        message.attachmentName != null)
                      _AttachmentPreview(
                        bytes: message.attachmentBytes!,
                        name: message.attachmentName!,
                        mime: message.attachmentMime ?? '',
                      ),
                    if (message.mediaKind == ChatMediaKind.voice &&
                        mediaProgress != null)
                      _PendingVoiceMessage(
                        progress: mediaProgress,
                        status: message.status,
                        failed: message.mediaFailed,
                        duration:
                            message.voiceDuration ?? const Duration(seconds: 1),
                        isMe: isMe,
                      )
                    else if (message.voicePath != null)
                      VoiceMessagePlayer(
                        path: message.voicePath!,
                        duration:
                            message.voiceDuration ?? const Duration(seconds: 1),
                        isMe: isMe,
                      ),
                    if (message.mediaKind == ChatMediaKind.videoCircle &&
                        mediaProgress != null)
                      _PendingVideoCircle(
                        progress: mediaProgress,
                        status: message.status,
                        failed: message.mediaFailed,
                        duration:
                            message.videoDuration ?? const Duration(seconds: 1),
                        isMe: isMe,
                      )
                    else if (message.videoPath != null)
                      VideoCirclePlayer(
                        path: message.videoPath!,
                        duration:
                            message.videoDuration ?? const Duration(seconds: 1),
                        isMe: isMe,
                        mirrorHorizontally: message.videoMirrorHorizontally,
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
                    if (message.taskStatus != null) ...[
                      const SizedBox(height: 8),
                      _TaskStatusBadge(status: message.taskStatus!),
                    ],
                    if (message.isPinned) ...[
                      const SizedBox(height: 8),
                      const _PinnedMessageBadge(),
                    ],
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
                color: cs.onSurface.withValues(alpha: 0.52),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showQuickMessageMenu(BuildContext context) async {
    final previewReactions = _quickReactionEmojis;
    final visibleFavorites = Set<String>.from(favoriteReactions);
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Действия'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Реакция',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 132,
                  child: Stack(
                    children: [
                      ClipRect(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final emoji in previewReactions.take(24))
                              _EmojiReactionButton(
                                emoji: emoji,
                                selected: message.reaction == emoji,
                                favorite: visibleFavorites.contains(emoji),
                                onTap: () => Navigator.pop(
                                  dialogContext,
                                  'reaction:$emoji',
                                ),
                                onLongPress: () {
                                  setDialogState(() {
                                    visibleFavorites.contains(emoji)
                                        ? visibleFavorites.remove(emoji)
                                        : visibleFavorites.add(emoji);
                                  });
                                  onToggleFavoriteReaction(emoji);
                                },
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.0),
                                Theme.of(context).colorScheme.surface,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(dialogContext, 'reactions:all'),
                      icon: const Icon(Icons.add_reaction_outlined),
                      label: const Text('Все реакции'),
                    ),
                    if (message.reaction != null)
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, 'reaction:clear'),
                        child: const Text('Снять'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Статус',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in MessageTaskStatus.values)
                      _StatusActionChip(
                        status: status,
                        selected: message.taskStatus == status,
                        onTap: () => Navigator.pop(
                          dialogContext,
                          'status:${status.name}',
                        ),
                      ),
                    if (message.taskStatus != null)
                      _SmallActionChip(
                        label: 'Без статуса',
                        onTap: () =>
                            Navigator.pop(dialogContext, 'status:clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _IconTextAction(
                      icon: Icons.reply_rounded,
                      label: 'Ответить',
                      onTap: () => Navigator.pop(dialogContext, 'reply'),
                    ),
                    if (message.text.isNotEmpty)
                      _IconTextAction(
                        icon: Icons.copy_rounded,
                        label: 'Копировать',
                        onTap: () => Navigator.pop(dialogContext, 'copy'),
                      ),
                    _IconTextAction(
                      icon: Icons.shortcut_rounded,
                      label: 'Переслать',
                      onTap: () => Navigator.pop(dialogContext, 'forward'),
                    ),
                    _IconTextAction(
                      icon: message.isPinned
                          ? Icons.push_pin_outlined
                          : Icons.push_pin_rounded,
                      label: message.isPinned
                          ? 'Открепить'
                          : 'Закрепить',
                      onTap: () => Navigator.pop(dialogContext, 'pin'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'reactions:all') {
      await _showAllReactionsMenu(context);
      return;
    }
    await _handleMessageAction(context, action);
  }

  List<String> get _quickReactionEmojis {
    final result = <String>[];
    for (final emoji in favoriteReactions) {
      if (!result.contains(emoji)) result.add(emoji);
    }
    for (final emoji in _defaultReactionEmojis) {
      if (!result.contains(emoji)) result.add(emoji);
    }
    return result;
  }

  Future<void> _showAllReactionsMenu(BuildContext context) async {
    final visibleFavorites = Set<String>.from(favoriteReactions);
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Все реакции'),
          content: SizedBox(
            width: 420,
            height: 420,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: _allReactionEmojis.length,
              itemBuilder: (_, index) {
                final emoji = _allReactionEmojis[index];
                return _EmojiReactionButton(
                  emoji: emoji,
                  selected: message.reaction == emoji,
                  favorite: visibleFavorites.contains(emoji),
                  onTap: () => Navigator.pop(dialogContext, 'reaction:$emoji'),
                  onLongPress: () {
                    setDialogState(() {
                      visibleFavorites.contains(emoji)
                          ? visibleFavorites.remove(emoji)
                          : visibleFavorites.add(emoji);
                    });
                    onToggleFavoriteReaction(emoji);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    await _handleMessageAction(context, action);
  }

  Future<void> _handleMessageAction(BuildContext context, String action) async {
    if (action.startsWith('reaction:')) {
      final value = action.substring('reaction:'.length);
      if (value == 'clear') {
        onReact(null);
        return;
      }
      onReact(message.reaction == value ? null : value);
      return;
    }

    if (action.startsWith('status:')) {
      final value = action.substring('status:'.length);
      if (value == 'clear') {
        onTaskStatus(null);
        return;
      }
      final status = MessageTaskStatus.values.firstWhere(
        (item) => item.name == value,
      );
      onTaskStatus(status);
      return;
    }

    switch (action) {
      case 'reply':
        onReply();
        break;
      case 'copy':
        await _copyMessageText(context);
        break;
      case 'pin':
        onPinned(!message.isPinned);
        break;
      case 'forward':
        await onForward();
        break;
      case 'select':
        _showLocalHint(context, 'Сообщение выделено');
        break;
    }
  }

  Future<void> _copyMessageText(BuildContext context) async {
    if (message.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: message.text));
    if (context.mounted) {
      _showLocalHint(context, 'Текст скопирован');
    }
  }

  void _showLocalHint(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _PendingVoiceMessage extends StatelessWidget {
  final double progress;
  final String status;
  final bool failed;
  final Duration duration;
  final bool isMe;

  const _PendingVoiceMessage({
    required this.progress,
    required this.status,
    required this.failed,
    required this.duration,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = failed ? cs.error : (isMe ? cs.primary : cs.secondary);
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 250,
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  value: clamped,
                  strokeWidth: 3,
                  backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              Icon(
                failed ? Icons.error_rounded : Icons.graphic_eq_rounded,
                color: accent,
                size: 22,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: clamped,
                    minHeight: 5,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        failed ? 'Ошибка' : _mediaProgressLabel(status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.72),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      failed
                          ? _formatDuration(duration)
                          : '${(clamped * 100).round()}%',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingVideoCircle extends StatelessWidget {
  final double progress;
  final String status;
  final bool failed;
  final Duration duration;
  final bool isMe;

  const _PendingVideoCircle({
    required this.progress,
    required this.status,
    required this.failed,
    required this.duration,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = failed ? cs.error : (isMe ? cs.primary : cs.secondary);
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 190,
      height: 204,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 188,
            height: 188,
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: 4,
              backgroundColor: cs.onSurface.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          Container(
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(cs.surfaceContainerHighest, accent, 0.10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  failed ? Icons.videocam_off_rounded : Icons.video_file_rounded,
                  color: accent,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  failed ? 'Ошибка' : '${(clamped * 100).round()}%',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  failed ? _formatDuration(duration) : _mediaProgressLabel(status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _mediaProgressLabel(String status) {
  return switch (status) {
    'сохранение' => 'Сохранение',
    'склейка' => 'Склейка',
    'подготовка' => 'Подготовка',
    'отправка' => 'Отправка',
    'отправлено' => 'Отправлено',
    _ => 'Подготовка',
  };
}

class _ReplyPreview extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _ReplyPreview({
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.38),
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
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForwardedBadge extends StatelessWidget {
  final String from;

  const _ForwardedBadge({required this.from});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shortcut_rounded, size: 15, color: cs.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Переслано от $from',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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

  bool get _isImage {
    final value = mime.toLowerCase();
    final n = name.toLowerCase();
    return value.startsWith('image/') ||
        n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.webp') ||
        n.endsWith('.gif');
  }

  bool get _isVideo {
    final value = mime.toLowerCase();
    final n = name.toLowerCase();
    return value.startsWith('video/') ||
        n.endsWith('.mp4') ||
        n.endsWith('.mov') ||
        n.endsWith('.avi') ||
        n.endsWith('.mkv') ||
        n.endsWith('.webm');
  }

  bool get _isAudio {
    final value = mime.toLowerCase();
    final n = name.toLowerCase();
    return value.startsWith('audio/') ||
        n.endsWith('.mp3') ||
        n.endsWith('.wav') ||
        n.endsWith('.m4a') ||
        n.endsWith('.aac') ||
        n.endsWith('.ogg') ||
        n.endsWith('.flac');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _AttachmentFrame(
        name: name,
        bytes: bytes,
        icon: _icon,
        child: _buildBody(context),
      ),
    );
  }

  IconData get _icon {
    if (_isImage) return Icons.image_rounded;
    if (_isVideo) return Icons.movie_rounded;
    if (_isAudio) return Icons.audiotrack_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Widget _buildBody(BuildContext context) {
    if (_isImage) {
      return _ImageAttachment(bytes: bytes, name: name);
    }
    if (_isVideo) {
      return _VideoAttachment(bytes: bytes, name: name);
    }
    if (_isAudio) {
      return _AudioAttachment(bytes: bytes, name: name);
    }
    return _FileAttachment(bytes: bytes, name: name, mime: mime);
  }
}

class _AttachmentFrame extends StatelessWidget {
  final String name;
  final Uint8List bytes;
  final IconData icon;
  final Widget child;

  const _AttachmentFrame({
    required this.name,
    required this.bytes,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: CorporateUi.panelAlt(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatBytes(bytes.length),
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.58),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Скачать',
                    onPressed: () => _saveAttachment(context, name, bytes),
                    icon: const Icon(Icons.download_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageAttachment extends StatelessWidget {
  final Uint8List bytes;
  final String name;

  const _ImageAttachment({required this.bytes, required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        height: 210,
        width: double.infinity,
      ),
    );
  }
}

class _VideoAttachment extends StatefulWidget {
  final Uint8List bytes;
  final String name;

  const _VideoAttachment({required this.bytes, required this.name});

  @override
  State<_VideoAttachment> createState() => _VideoAttachmentState();
}

class _VideoAttachmentState extends State<_VideoAttachment> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      final file = await _writeTempAttachment(widget.name, widget.bytes);
      final controller = VideoPlayerController.file(file);
      await controller.initialize().timeout(const Duration(seconds: 8));
      await controller.setLooping(false);
      await controller.setVolume(1);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return const SizedBox(
        height: 156,
        child: Center(
            child: Text('Видео не удалось открыть')),
      );
    }
    if (controller == null) {
      return const SizedBox(
        height: 156,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return GestureDetector(
      onTap: () async {
        if (controller.value.isPlaying) {
          await controller.pause();
        } else {
          if (controller.value.position >= controller.value.duration) {
            await controller.seekTo(Duration.zero);
          }
          await controller.play();
        }
      },
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.44),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AudioAttachment extends StatefulWidget {
  final Uint8List bytes;
  final String name;

  const _AudioAttachment({required this.bytes, required this.name});

  @override
  State<_AudioAttachment> createState() => _AudioAttachmentState();
}

class _AudioAttachmentState extends State<_AudioAttachment> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.setVolume(1);
    _player.onPositionChanged.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    _player.onDurationChanged.listen((value) {
      if (mounted) setState(() => _duration = value);
    });
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _duration.inMilliseconds <= 0 ? 1 : _duration.inMilliseconds;
    final progress = (_position.inMilliseconds / total).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: _playing ? 'Пауза' : 'Воспроизвести',
            onPressed: _toggle,
            icon: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: cs.onSurface.withValues(alpha: 0.10),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_position >= _duration && _duration > Duration.zero) {
      await _player.seek(Duration.zero);
    }
    await _player.play(BytesSource(widget.bytes));
  }
}

class _FileAttachment extends StatelessWidget {
  final Uint8List bytes;
  final String name;
  final String mime;

  const _FileAttachment({
    required this.bytes,
    required this.name,
    required this.mime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description_rounded, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mime.isEmpty ? 'Файл' : mime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.64),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _saveAttachment(
  BuildContext context,
  String name,
  Uint8List bytes,
) async {
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить вложение',
      fileName: name,
      bytes: bytes,
    );
    if (path == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Сохранено: $path')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Не удалось сохранить файл: $e')),
    );
  }
}

Future<File> _writeTempAttachment(String name, Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
  final file = File(
    '${dir.path}/attachment_${DateTime.now().microsecondsSinceEpoch}_$safeName',
  );
  return file.writeAsBytes(bytes, flush: true);
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(1)} GB';
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString();
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

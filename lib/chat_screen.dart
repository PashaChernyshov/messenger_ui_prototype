// chat_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:characters/characters.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String lastMessage;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.lastMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static final Map<String, List<Message>> _chatHistory = {};
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();

  bool _isMuted = false;
  bool _isPinned = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    if (widget.lastMessage.characters.isNotEmpty) {
      _messages.add(Message(
        text: widget.lastMessage,
        sender: Sender.other,
      ));
    }
  }

  void _loadMessages() {
    _messages.addAll(_chatHistory[widget.userName] ?? []);
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.characters.isEmpty) return;
    final message = Message(text: text, sender: Sender.me);
    setState(() {
      _messages.add(message);
      _chatHistory[widget.userName] = [
        ...?_chatHistory[widget.userName],
        message
      ];
      _controller.clear();
    });
  }

  Future<void> _sendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null) return;
      final file = result.files.single;
      final ext = (file.extension ?? '').toLowerCase();
      final isImage = ext == 'jpg' ||
          ext == 'jpeg' ||
          ext == 'png' ||
          ext == 'gif' ||
          ext == 'webp';

      final message = Message(
        text: file.name,
        sender: Sender.me,
        fileBytes: file.bytes,
        fileName: file.name,
        isImage: isImage,
        filePath: file.path,
      );

      setState(() {
        _messages.add(message);
        _chatHistory[widget.userName] = [
          ...?_chatHistory[widget.userName],
          message
        ];
      });
    } catch (e) {
      debugPrint('Ошибка при отправке файла: $e');
    }
  }

  Future<void> _onOpenLink(LinkableElement link) async {
    final uri = Uri.parse(link.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Не удалось открыть ссылку: $uri");
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  _isPinned ? 'Открепить чат' : 'Закрепить чат',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    _isPinned = !_isPinned;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  _isMuted ? Icons.notifications_off : Icons.notifications,
                  color: Colors.white,
                ),
                title: Text(
                  _isMuted ? 'Включить звук' : 'Отключить звук',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    _isMuted = !_isMuted;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Очистить чат',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _chatHistory[widget.userName] = [];
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCallOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.call, color: Colors.white),
                title: const Text("Позвонить",
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.white),
                title: const Text("Видео-звонок",
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.sender == Sender.me;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe ? Colors.blueAccent : const Color(0xFF2A2A2A);

    Widget content;
    if (message.fileBytes != null || message.filePath != null) {
      content = _buildFileBubble(message);
    } else {
      content = Linkify(
        text: message.text,
        style: const TextStyle(color: Colors.white),
        linkStyle: const TextStyle(
          color: Colors.lightBlueAccent,
          decoration: TextDecoration.underline,
        ),
        onOpen: _onOpenLink,
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: content,
      ),
    );
  }

  Widget _buildFileBubble(Message message) {
    if (message.isImage) {
      if (UniversalPlatform.isWeb) {
        return Text(
          '[Изображение] ${message.fileName}',
          style: const TextStyle(color: Colors.white),
        );
      } else {
        if (message.filePath != null && File(message.filePath!).existsSync()) {
          return Image.file(
            File(message.filePath!),
            width: 200,
            height: 150,
            fit: BoxFit.cover,
          );
        } else if (message.fileBytes != null) {
          return Image.memory(
            message.fileBytes!,
            width: 200,
            height: 150,
            fit: BoxFit.cover,
          );
        } else {
          return Text(
            '[Изображение] ${message.fileName}',
            style: const TextStyle(color: Colors.white),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.fileName ?? 'Файл',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (!UniversalPlatform.isWeb)
          TextButton.icon(
            onPressed: () async {
              if (message.fileBytes != null) {
                final directory = await getApplicationDocumentsDirectory();
                final filePath = '${directory.path}/${message.fileName}';
                final file = File(filePath);
                await file.writeAsBytes(message.fileBytes!);
                debugPrint("Файл сохранён: $filePath");
              } else if (message.filePath != null) {
                debugPrint("Файл уже на диске: ${message.filePath}");
              }
            },
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text("Скачать", style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF1C1C1E);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _showCallOptions,
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _showCallOptions,
          ),
          PopupMenuButton<String>(
            color: Colors.grey[900],
            onSelected: (value) {
              switch (value) {
                case 'more':
                  _showMoreOptions();
                  break;
                case 'toggle_notifications':
                  setState(() {
                    _notificationsEnabled = !_notificationsEnabled;
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_notifications',
                child: Row(
                  children: [
                    Icon(
                      _notificationsEnabled
                          ? Icons.notifications
                          : Icons.notifications_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _notificationsEnabled
                          ? 'Выключить уведомления'
                          : 'Включить уведомления',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'more',
                child: Row(
                  children: [
                    Icon(Icons.more_horiz, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Ещё', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white),
                  onPressed: _sendFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Напишите сообщение…',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFABs(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFABs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FloatingActionButton.small(
              heroTag: 'scrollDown',
              backgroundColor: Colors.grey[850],
              onPressed: () {},
              child: const Icon(Icons.arrow_downward, color: Colors.white),
            ),
          ),
        FloatingActionButton(
          heroTag: 'newMessage',
          backgroundColor: Colors.blueAccent,
          onPressed: () {},
          child: const Icon(Icons.edit, color: Colors.white),
        ),
      ],
    );
  }
}

class Message {
  final String text;
  final String? filePath;
  final String? fileName;
  final Uint8List? fileBytes;
  final bool isImage;
  final Sender sender;

  Message({
    this.text = '',
    this.filePath,
    this.fileName,
    this.fileBytes,
    this.isImage = false,
    required this.sender,
  });
}

enum Sender { me, other }

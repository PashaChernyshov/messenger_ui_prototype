import 'package:characters/characters.dart';

class Contact {
  final String jid; // КРИТИЧНО для XMPP
  final String displayName;

  final String? lastMessage;
  final String? time;
  final String? avatarUrl;
  final String? status;

  const Contact({
    required this.jid,
    required this.displayName,
    this.lastMessage,
    this.time,
    this.avatarUrl,
    this.status,
  });

  String get initials {
    final s = displayName.trim();
    if (s.isEmpty) return '?';
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    final a = parts.first.characters.take(1).toString().toUpperCase();
    final b = parts.last.characters.take(1).toString().toUpperCase();
    return '$a$b';
  }

  Map<String, dynamic> toJson() => {
        'jid': jid,
        'displayName': displayName,
        'lastMessage': lastMessage,
        'time': time,
        'avatarUrl': avatarUrl,
        'status': status,
      };

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      jid: (json['jid'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
      lastMessage: json['lastMessage']?.toString(),
      time: json['time']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      status: json['status']?.toString(),
    );
  }
}


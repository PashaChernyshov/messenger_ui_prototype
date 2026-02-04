import 'package:characters/characters.dart';

class Contact {
  final String jid;
  final String displayName;
  final String? lastMessage;
  final String? time;
  final String? status;

  const Contact({
    required this.jid,
    required this.displayName,
    this.lastMessage,
    this.time,
    this.status,
  });

  String get initials {
    final t = displayName.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    final a = parts.first.characters.take(1).toString().toUpperCase();
    final b = parts.last.characters.take(1).toString().toUpperCase();
    return '$a$b';
  }
}

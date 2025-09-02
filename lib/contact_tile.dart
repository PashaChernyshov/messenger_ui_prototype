// contact_tile.dart
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'contact.dart';
import 'contact_info_popup.dart';
import 'package:characters/characters.dart';

class ContactTile extends StatefulWidget {
  final Contact contact;

  const ContactTile({super.key, required this.contact});

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        color: _isHovered ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
        elevation: _isHovered ? 4 : 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: GestureDetector(
            onTap: () {
              // Всплывающее окно с подробной инфой (реализовано отдельно)
              showContactInfoPopup(context, contact);
            },
            child: CircleAvatar(
              backgroundImage:
                  contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
                      ? NetworkImage(contact.avatarUrl!)
                      : null,
              backgroundColor: const Color(0xFF3A3A3C),
              child: (contact.avatarUrl == null || contact.avatarUrl!.isEmpty)
                  ? Text(
                      (contact.name.characters.isEmpty
                              ? '#'
                              : contact.name.characters.first)
                          .toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
          ),
          title: Text(
            contact.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${contact.lastMessage} • ${contact.time}',
            style: const TextStyle(color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  userName: contact.name,
                  lastMessage: contact.lastMessage,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:app_design/features/contacts/domain/contact.dart';
import 'package:app_design/features/contacts/presentation/widgets/contact_tile.dart';

class ContactListScreen extends StatelessWidget {
  final List<Contact> contacts;
  final void Function(Contact) onOpenChat;

  const ContactListScreen({
    super.key,
    required this.contacts,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const Center(
        child: Text('Контактов нет', style: TextStyle(color: Colors.white60)),
      );
    }

    // Группировка по первой букве displayName
    final grouped = <String, List<Contact>>{};
    for (final c in contacts) {
      final key =
          c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '#';
      grouped.putIfAbsent(key, () => []).add(c);
    }

    final keys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final k = keys[i];
        final list = grouped[k]!
          ..sort((a, b) => a.displayName.compareTo(b.displayName));

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                k,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 10),
              ...list.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ContactTile(
                    contact: c,
                    onOpenChat: () => onOpenChat(c),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

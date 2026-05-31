import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../contacts/controller/contacts_controller.dart';
import '../../contacts/data/contact.dart';
import 'widgets/contact_tile.dart';
import 'popups/contact_info_popup.dart';

class ContactListScreen extends StatelessWidget {
  const ContactListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<ContactsController>().contacts;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Color.lerp(Colors.black, cs.surface, 0.22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Контакты'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final c = contacts[i];
          return ContactTile(
            contact: c,
            onTap: () => _openContact(context, c),
            onInfo: () => showContactInfoPopup(context, contact: c),
          );
        },
      ),
    );
  }

  void _openContact(BuildContext context, Contact c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Контакт: ${c.displayName}')),
    );
  }
}

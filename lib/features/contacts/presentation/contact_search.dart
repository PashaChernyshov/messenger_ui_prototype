import 'package:flutter/material.dart';

import 'package:app_design/features/contacts/domain/contact.dart';
import 'package:app_design/core/ui/corporate_ui.dart';

class ContactSearchDelegate extends SearchDelegate {
  final List<Contact> contacts;
  final void Function(Contact) onOpenChat;

  ContactSearchDelegate({
    required this.contacts,
    required this.onOpenChat,
  });

  @override
  String get searchFieldLabel => 'Поиск...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _build(context);

  @override
  Widget buildSuggestions(BuildContext context) => _build(context);

  Widget _build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? contacts
        : contacts
            .where((c) =>
                c.displayName.toLowerCase().contains(q) ||
                c.jid.toLowerCase().contains(q))
            .toList();

    if (filtered.isEmpty) {
      return const Center(
        child:
            Text('Ничего не найдено', style: TextStyle(color: Colors.white60)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = filtered[i];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CorporateUi.radius),
            side: BorderSide(color: Colors.transparent),
          ),
          tileColor: Theme.of(context).colorScheme.surface,
          leading: CorporateAvatar(initials: c.initials),
          title:
              Text(c.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(c.jid, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            close(context, null);
            onOpenChat(c);
          },
        );
      },
    );
  }
}


import 'package:flutter/material.dart';

import '../data/contact.dart';
import 'popups/contact_info_popup.dart';

class ContactSearchDelegate extends SearchDelegate<Contact?> {
  final List<Contact> contacts;
  final void Function(Contact) onOpenChat;

  ContactSearchDelegate({
    required this.contacts,
    required this.onOpenChat,
  });

  @override
  String get searchFieldLabel => 'Поиск контактов';

  @override
  TextStyle? get searchFieldStyle =>
      const TextStyle(fontWeight: FontWeight.w700);

  List<Contact> _filtered() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return contacts;
    return contacts.where((c) {
      final a = c.displayName.toLowerCase();
      final b = c.jid.toLowerCase();
      return a.contains(q) || b.contains(q);
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Очистить',
          onPressed: () => query = '',
          icon: const Icon(Icons.close_rounded),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Назад',
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final list = _filtered();

    if (list.isEmpty) {
      return const Center(
        child:
            Text('Ничего не найдено', style: TextStyle(color: Colors.white60)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = list[i];
        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.45),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 26,
                  spreadRadius: -10,
                  offset: const Offset(0, 14),
                  color: Colors.black.withOpacity(0.25),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                close(context, c);
                onOpenChat(c);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => showContactInfoPopup(context, contact: c),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.surface.withOpacity(0.55),
                        child: Text(
                          c.initials,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface.withOpacity(0.92),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.jid,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.62),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurface.withOpacity(0.38)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

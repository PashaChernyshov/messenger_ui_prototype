import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_design/app/state/app_state.dart';
import 'package:app_design/features/contacts/domain/contact.dart';
import 'package:app_design/core/ui/corporate_ui.dart';

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final name = TextEditingController();
  final search = TextEditingController();
  final Set<String> selectedJids = {};

  @override
  void dispose() {
    name.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final q = search.text.trim().toLowerCase();

    final list = q.isEmpty
        ? app.contacts
        : app.contacts
            .where((c) =>
                c.displayName.toLowerCase().contains(q) ||
                c.jid.toLowerCase().contains(q))
            .toList();

    final canCreate = name.text.trim().isNotEmpty && selectedJids.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание группы'),
        actions: [
          TextButton(
            onPressed: canCreate ? () => _create(context) : null,
            child: const Text('Создать'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: CorporateUi.pagePadding,
        children: [
          TextField(
            controller: name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Название группы',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Поиск контактов',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          CorporatePanel(
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.62),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Выбрано: ${selectedJids.length}. Группы хранятся локально на этом устройстве.',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.62),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (app.contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
                'Нет контактов. Подключитесь к XMPP в настройках или создайте демо-чат во вкладке чатов.',
                style: TextStyle(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...list.map((c) => _ContactPickRow(
                  contact: c,
                  selected: selectedJids.contains(c.jid),
                  onToggle: () {
                    setState(() {
                      if (selectedJids.contains(c.jid)) {
                        selectedJids.remove(c.jid);
                      } else {
                        selectedJids.add(c.jid);
                      }
                    });
                  },
                )),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final app = context.read<AppState>();
    await app.createGroup(
      name: name.text.trim(),
      memberJids: selectedJids.toList(),
    );
    if (mounted) Navigator.pop(context);
  }
}

class _ContactPickRow extends StatelessWidget {
  final Contact contact;
  final bool selected;
  final VoidCallback onToggle;

  const _ContactPickRow({
    required this.contact,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CorporateUi.radius),
          side: BorderSide(color: Colors.transparent),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(CorporateUi.radius),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CorporateAvatar(initials: contact.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(contact.jid,
                          style: const TextStyle(color: Colors.white60),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Checkbox(value: selected, onChanged: (_) => onToggle()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


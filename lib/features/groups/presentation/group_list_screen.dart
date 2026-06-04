import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_design/app/state/app_state.dart';
import 'package:app_design/core/ui/corporate_ui.dart';
import 'package:app_design/features/groups/presentation/group_chat_screen.dart';
import 'package:app_design/features/groups/presentation/group_creation_screen.dart';
import 'package:app_design/features/groups/presentation/view_models/group_card_view_model.dart';
import 'package:app_design/features/groups/presentation/widgets/group_expandable_card.dart';

class GroupListScreen extends StatefulWidget {
  final bool embedded;

  const GroupListScreen({super.key, this.embedded = false});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  String? _expandedGroupId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    final body = app.groups.isEmpty
        ? _Empty(onCreate: () => _openCreate(context))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            itemCount: app.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final group = app.groups[index];
              final peerKey = app.groupPeerKey(group.id);
              final card = GroupCardViewModel.from(
                group: group,
                messages: app.chatOf(peerKey),
              );

              return GroupExpandableCard(
                group: card,
                expanded: _expandedGroupId == group.id,
                onToggle: () => _toggleGroup(group.id),
                onOpen: () => _openGroupChat(context, group.id),
                onDelete: () => _confirmDelete(context, group.id, group.name),
              );
            },
          );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы'),
        actions: [
          IconButton(
            tooltip: 'Создать',
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: body,
    );
  }

  void _toggleGroup(String groupId) {
    setState(() {
      _expandedGroupId = _expandedGroupId == groupId ? null : groupId;
    });
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupCreationScreen()),
    );
  }

  void _openGroupChat(BuildContext context, String groupId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: groupId)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String groupId,
    String name,
  ) async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить группу?'),
        content: Text('"$name" будет удалена с этого устройства.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await app.deleteGroup(groupId);
      if (mounted && _expandedGroupId == groupId) {
        setState(() => _expandedGroupId = null);
      }
    }
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;

  const _Empty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: CorporatePanel(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Групп пока нет',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Создайте группу, чтобы начать обсуждение.\nСейчас группы хранятся локально.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('Создать группу'),
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


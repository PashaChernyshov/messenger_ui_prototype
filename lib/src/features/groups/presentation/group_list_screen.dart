import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/groups_controller.dart';
import '../data/group.dart';
import 'group_creation_screen.dart';

class GroupListScreen extends StatelessWidget {
  final bool embedded;

  const GroupListScreen({
    super.key,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final groupsController = context.watch<GroupsController>();
    final groups = groupsController.groups;

    final content = groups.isEmpty
        ? _EmptyPanel(
            onCreate: () => _createGroupFlow(context),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _GroupCard(
              group: groups[i],
              onOpen: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GroupChatScreen ещё не подключен.'),
                  ),
                );
              },
              onDelete: () async {
                await groupsController.deleteGroup(groups[i].id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Группа удалена')),
                  );
                }
              },
            ),
          );

    if (embedded) return content;

    return Scaffold(
      backgroundColor: Color.lerp(Colors.black, cs.surface, 0.22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Группы',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Создать',
            onPressed: () => _createGroupFlow(context),
            icon: const Icon(Icons.group_add_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createGroupFlow(context),
        child: const Icon(Icons.group_add_rounded),
      ),
    );
  }

  Future<void> _createGroupFlow(BuildContext context) async {
    final result = await Navigator.push<GroupCreationResult>(
      context,
      MaterialPageRoute(builder: (_) => const GroupCreationScreen()),
    );

    if (result == null) return;

    final title = result.name.trim();
    if (title.isEmpty) return;

    await context.read<GroupsController>().createGroup(
          name: title,
          memberJids: result.memberJids,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Группа создана')),
      );
    }
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _GroupCard({
    required this.group,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cs.surface.withOpacity(0.40),
                    border: Border.all(color: cs.onSurface.withOpacity(0.08)),
                  ),
                  child: Icon(Icons.groups_rounded,
                      color: cs.onSurface.withOpacity(0.78)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Участников: ${group.memberJids.length} • ${_fmt(group.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.70),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $h:$mi';
  }
}

class _EmptyPanel extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyPanel({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.45),
                  border: Border.all(color: cs.onSurface.withOpacity(0.10)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(cs.primary, cs.onSurface, 0.45)!
                                .withOpacity(0.88),
                            Color.lerp(cs.primary, cs.onSurface, 0.45)!
                                .withOpacity(0.18),
                          ],
                        ),
                      ),
                      child:
                          const Icon(Icons.groups_rounded, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Пока нет групп',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Создай первую группу.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.70),
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.group_add_rounded),
                        label: const Text('Создать группу'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

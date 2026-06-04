import 'package:flutter/material.dart';

import 'package:app_design/core/ui/corporate_ui.dart';
import 'package:app_design/features/groups/presentation/view_models/group_card_view_model.dart';

class GroupExpandableCard extends StatelessWidget {
  final GroupCardViewModel group;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const GroupExpandableCard({
    super.key,
    required this.group,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(CorporateUi.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(CorporateUi.radius),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _GroupHeader(group: group, expanded: expanded),
              if (expanded) ...[
                const SizedBox(height: 14),
                _GroupDetails(group: group),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.forum_rounded, size: 18),
                        label: const Text('Перейти в группу'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Удалить группу',
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: cs.error.withOpacity(0.86),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final GroupCardViewModel group;
  final bool expanded;

  const _GroupHeader({
    required this.group,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        CorporateAvatar(initials: group.initials),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.memberCountText,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.58),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                group.activityText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.66),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          expanded
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          color: cs.onSurface.withOpacity(0.54),
        ),
      ],
    );
  }
}

class _GroupDetails extends StatelessWidget {
  final GroupCardViewModel group;

  const _GroupDetails({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaChip(text: group.statusText, icon: Icons.storage_rounded),
            _MetaChip(text: group.createdAtText, icon: Icons.event_rounded),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Участники',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface.withOpacity(0.74),
          ),
        ),
        const SizedBox(height: 8),
        if (group.memberPreview.isEmpty)
          Text(
            'Участники пока не добавлены',
            style: TextStyle(color: cs.onSurface.withOpacity(0.54)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.memberPreview
                .map((jid) => _MemberChip(label: jid))
                .toList(),
          ),
        const SizedBox(height: 14),
        Text(
          'Последние сообщения',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onSurface.withOpacity(0.74),
          ),
        ),
        const SizedBox(height: 8),
        if (!group.hasMessages)
          Text(
            'История сообщений появится после начала обсуждения.',
            style: TextStyle(color: cs.onSurface.withOpacity(0.54)),
          )
        else
          Column(
            children: group.messagePreview
                .map((message) => _MessagePreviewRow(message: message))
                .toList(),
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _MetaChip({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.72),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String label;

  const _MemberChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: cs.onSurface.withOpacity(0.72),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MessagePreviewRow extends StatelessWidget {
  final GroupMessagePreview message;

  const _MessagePreviewRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              message.time,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurface.withOpacity(0.42),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${message.author}: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: message.body),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.68),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


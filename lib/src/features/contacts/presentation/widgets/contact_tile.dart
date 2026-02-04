import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../contacts/data/contact.dart';

class ContactTile extends StatelessWidget {
  final Contact contact;
  final Uint8List? avatarBytes;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  const ContactTile({
    super.key,
    required this.contact,
    required this.onTap,
    required this.onInfo,
    this.avatarBytes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isOnline = (contact.status ?? '').toLowerCase() == 'online';
    final accent = Color.lerp(cs.primary, cs.onSurface, 0.45)!;

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onInfo,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withOpacity(0.88),
                              accent.withOpacity(0.18),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: cs.surface.withOpacity(0.55),
                          backgroundImage: avatarBytes == null
                              ? null
                              : MemoryImage(avatarBytes!),
                          child: avatarBytes == null
                              ? Text(
                                  contact.initials,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                    color: cs.onSurface.withOpacity(0.92),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? Colors.greenAccent.shade400
                                : cs.onSurface.withOpacity(0.22),
                            border: Border.all(
                              color: cs.surface.withOpacity(0.95),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contact.jid,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.55),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../contacts/controller/contacts_controller.dart';
import '../../contacts/data/contact.dart';

class GroupCreationResult {
  final String name;
  final List<String> memberJids;

  const GroupCreationResult({
    required this.name,
    required this.memberJids,
  });
}

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final name = TextEditingController();
  final search = TextEditingController();

  final Set<String> selected = <String>{};

  @override
  void dispose() {
    name.dispose();
    search.dispose();
    super.dispose();
  }

  Color _bg(ColorScheme cs) => Color.lerp(Colors.black, cs.surface, 0.22)!;
  Color _mutedAccent(ColorScheme cs) =>
      Color.lerp(cs.primary, cs.onSurface, 0.45)!;

  @override
  Widget build(BuildContext context) {
    final contactsCtl = context.watch<ContactsController>();
    final contacts = contactsCtl.contacts;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = _bg(cs);
    final accent = _mutedAccent(cs);

    final query = search.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? contacts
        : contacts.where((c) {
            final dn = c.displayName.toLowerCase();
            final jid = c.jid.toLowerCase();
            return dn.contains(query) || jid.contains(query);
          }).toList();

    final canCreate = name.text.trim().isNotEmpty && selected.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 64,
        flexibleSpace: _FrostedBar(
          tint: cs.surface.withOpacity(0.52),
          border: cs.onSurface.withOpacity(0.08),
        ),
        titleSpacing: 14,
        title: Row(
          children: [
            _AppMark(icon: Icons.group_add_rounded, accent: accent),
            const SizedBox(width: 10),
            Text(
              'Новая группа',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12 + 64, 14, 18),
          children: [
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Field(
                    label: 'Название',
                    controller: name,
                    prefixIcon: Icons.badge_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    label: 'Поиск участников',
                    controller: search,
                    prefixIcon: Icons.search_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (selected.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selected
                          .map((jid) => _SelectedChip(
                                jid: jid,
                                contact: _findContact(contacts, jid),
                                onRemove: () =>
                                    setState(() => selected.remove(jid)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _SectionTitle('Участники'),
                  const SizedBox(height: 10),
                  _ContactsPickList(
                    contacts: filtered,
                    selected: selected,
                    onToggle: (jid) {
                      setState(() {
                        if (!selected.add(jid)) selected.remove(jid);
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: canCreate
                          ? () {
                              final title = name.text.trim();
                              final members = selected.toList()..sort();
                              Navigator.pop(
                                context,
                                GroupCreationResult(
                                    name: title, memberJids: members),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Создать'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Contact? _findContact(List<Contact> list, String jid) {
    try {
      return list.firstWhere((c) => c.jid == jid);
    } catch (_) {
      return null;
    }
  }
}

/* ===== widgets ===== */

class _ContactsPickList extends StatelessWidget {
  final List<Contact> contacts;
  final Set<String> selected;
  final void Function(String jid) onToggle;

  const _ContactsPickList({
    required this.contacts,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Контактов нет. Сначала создай/добавь контакты в «Чатах».',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withOpacity(0.10)),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            color: cs.onSurface.withOpacity(0.06),
          ),
          itemBuilder: (_, i) {
            final c = contacts[i];
            final checked = selected.contains(c.jid);

            return InkWell(
              onTap: () => onToggle(c.jid),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    _AvatarMini(initials: c.initials),
                    const SizedBox(width: 10),
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
                          const SizedBox(height: 2),
                          Text(
                            c.jid,
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
                    const SizedBox(width: 10),
                    Checkbox(
                      value: checked,
                      onChanged: (_) => onToggle(c.jid),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  final String jid;
  final Contact? contact;
  final VoidCallback onRemove;

  const _SelectedChip({
    required this.jid,
    required this.contact,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = contact?.displayName ?? jid;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.35),
            border: Border.all(color: cs.onSurface.withOpacity(0.10)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withOpacity(0.86),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onRemove,
                child: Icon(Icons.close_rounded,
                    size: 18, color: cs.onSurface.withOpacity(0.70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarMini extends StatelessWidget {
  final String initials;
  const _AvatarMini({required this.initials});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surface.withOpacity(0.40),
        border: Border.all(color: cs.onSurface.withOpacity(0.10)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: cs.onSurface.withOpacity(0.90),
        ),
      ),
    );
  }
}

/* ===== glass ===== */

class _FrostedBar extends StatelessWidget {
  final Color tint;
  final Color border;

  const _FrostedBar({required this.tint, required this.border});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            border: Border(bottom: BorderSide(color: border)),
          ),
        ),
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _AppMark({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.92), accent.withOpacity(0.25)],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.28),
          ),
        ],
        border: Border.all(color: cs.onSurface.withOpacity(0.08)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.45),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.onSurface.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 26,
                spreadRadius: -10,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.25),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.w900,
        color: cs.onSurface.withOpacity(0.60),
        letterSpacing: 0.8,
        fontSize: 12,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.label,
    required this.controller,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        color: cs.onSurface.withOpacity(0.92),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: cs.onSurface.withOpacity(0.60)),
        filled: true,
        fillColor: cs.surface.withOpacity(0.35),
        labelStyle: TextStyle(
          color: cs.onSurface.withOpacity(0.58),
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.18)),
        ),
      ),
    );
  }
}

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../calls/controller/calls_controller.dart';
import '../../chats/controller/chats_controller.dart';
import '../../chats/presentation/chat_screen.dart';
import '../../contacts/controller/contacts_controller.dart';
import '../../contacts/data/contact.dart';
import '../../contacts/presentation/contact_search.dart';
import '../../contacts/presentation/popups/contact_info_popup.dart';
import '../../groups/controller/groups_controller.dart';
import '../../groups/presentation/group_creation_screen.dart';
import '../../groups/presentation/group_list_screen.dart';
import '../../menu/presentation/menu.dart';
import '../../profile/controller/profile_controller.dart';
import '../../xmpp/controller/xmpp_controller.dart';

import '../presentation/widgets/hover_effect.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0; // 0=Chats, 1=Groups, 2=Calls

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 980;

  String _tabLabel(int i) => switch (i) {
        0 => 'Чаты',
        1 => 'Группы',
        _ => 'Звонки',
      };

  IconData _tabIcon(int i) => switch (i) {
        0 => Icons.chat_bubble_rounded,
        1 => Icons.groups_rounded,
        _ => Icons.call_rounded,
      };

  Color _mutedAccent(ColorScheme cs) {
    return Color.lerp(cs.primary, cs.onSurface, 0.45)!;
  }

  Color _pageBg(ColorScheme cs) {
    return Color.lerp(Colors.black, cs.surface, 0.22)!;
  }

  @override
  Widget build(BuildContext context) {
    final xmpp = context.watch<XmppController>();
    final profile = context.watch<ProfileController>();
    final contacts = context.watch<ContactsController>();
    final calls = context.watch<CallsController>();

    final wide = _isWide(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final accent = _mutedAccent(cs);
    final bg = _pageBg(cs);

    Widget body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final fade = FadeTransition(opacity: anim, child: child);
        final slide = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(anim),
          child: fade,
        );
        return slide;
      },
      child: KeyedSubtree(
        key: ValueKey(index),
        child: _buildBody(context, contacts.contacts),
      ),
    );

    if (wide) {
      body = Row(
        children: [
          _GlassRail(
            selectedIndex: index,
            onSelected: (v) => setState(() => index = v),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.22),
                    border: Border.all(color: cs.onSurface.withOpacity(0.07)),
                  ),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      extendBody: !wide,
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
            _AppMark(icon: _tabIcon(index), accent: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Мессенджер',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tabLabel(index),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.68),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _ConnectionChip(
            status: xmpp.status,
            hint: xmpp.hint,
            onTap: () async {
              if (xmpp.status == ConnectionStatus.connected) {
                await xmpp.disconnect();
              } else {
                await xmpp.connect();
              }
            },
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Поиск',
            onPressed: () {
              showSearch(
                context: context,
                delegate: ContactSearchDelegate(
                  contacts: contacts.contacts,
                  onOpenChat: _openChat,
                ),
              );
            },
            icon: const Icon(Icons.search_rounded),
            style: IconButton.styleFrom(
              backgroundColor: cs.surface.withOpacity(0.28),
              foregroundColor: cs.onSurface.withOpacity(0.92),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.onSurface.withOpacity(0.08)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Меню',
            onPressed: () => showAppMenuSheet(context),
            icon: const Icon(Icons.more_horiz_rounded),
            style: IconButton.styleFrom(
              backgroundColor: cs.surface.withOpacity(0.28),
              foregroundColor: cs.onSurface.withOpacity(0.92),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.onSurface.withOpacity(0.08)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ProfileAvatar(
              bytes: profile.profile.avatarBytes,
              initials: _initials(profile.profile.name),
              accent: accent,
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.25),
              bg.withOpacity(0.00),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: wide
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                  child: body,
                )
              : body,
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : _GlassBottomNav(
              currentIndex: index,
              onTap: (v) => setState(() => index = v),
              accent: accent,
            ),
      floatingActionButton: index == 0
          ? _GlassFab(
              icon: Icons.add_comment_rounded,
              label: 'Новый чат',
              onTap: () => _createStubChat(context),
            )
          : index == 1
              ? _GlassFab(
                  icon: Icons.group_add_rounded,
                  label: 'Новая группа',
                  onTap: () => _createGroup(context),
                )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _initials(String name) {
    final s = name.trim();
    if (s.isEmpty) return '?';
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    final a = parts.first.characters.take(1).toString().toUpperCase();
    final b = parts.last.characters.take(1).toString().toUpperCase();
    return '$a$b';
  }

  Widget _buildBody(BuildContext context, List<Contact> contacts) {
    if (index == 0) {
      return _ChatsTab(contacts: contacts, onOpenChat: _openChat);
    }
    if (index == 1) return const GroupListScreen(embedded: true);
    return const _CallsPanel();
  }

  void _openChat(Contact c) {
    final chats = context.read<ChatsController>();
    chats.ensureChatSeed(c.jid, c.displayName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerJid: c.jid,
          peerName: c.displayName,
        ),
      ),
    );
  }

  void _createStubChat(BuildContext context) {
    final xmpp = context.read<XmppController>();
    final contacts = context.read<ContactsController>();

    final contact = contacts.createStubContact(domain: xmpp.domain);
    _openChat(contact);
  }

  Future<void> _createGroup(BuildContext context) async {
    final res = await Navigator.push<GroupCreationResult>(
      context,
      MaterialPageRoute(builder: (_) => const GroupCreationScreen()),
    );

    if (res == null) return;

    final groups = context.read<GroupsController>();
    await groups.createGroup(name: res.name, memberJids: res.memberJids);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Группа создана')),
    );
  }
}

/* ===== Ниже UI блоки — без логических изменений ===== */

class _GlassRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _GlassRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  Color _mutedAccent(ColorScheme cs) {
    return Color.lerp(cs.primary, cs.onSurface, 0.45)!;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _mutedAccent(cs);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: 92,
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.58),
                border: Border.all(color: cs.onSurface.withOpacity(0.10)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  navigationRailTheme: NavigationRailThemeData(
                    backgroundColor: Colors.transparent,
                    indicatorColor: accent.withOpacity(0.16),
                    selectedIconTheme:
                        IconThemeData(color: cs.onSurface.withOpacity(0.92)),
                    unselectedIconTheme:
                        IconThemeData(color: cs.onSurface.withOpacity(0.55)),
                    selectedLabelTextStyle: TextStyle(
                      color: cs.onSurface.withOpacity(0.86),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                      fontSize: 12,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: cs.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      fontSize: 12,
                    ),
                  ),
                ),
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.85,
                  useIndicator: true,
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      selectedIcon: Icon(Icons.chat_bubble_rounded),
                      label: Text('Чаты'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.groups_outlined),
                      selectedIcon: Icon(Icons.groups_rounded),
                      label: Text('Группы'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.call_outlined),
                      selectedIcon: Icon(Icons.call_rounded),
                      label: Text('Звонки'),
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

class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accent;

  const _GlassBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.65),
                border: Border.all(color: cs.onSurface.withOpacity(0.10)),
              ),
              child: NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: onTap,
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: accent.withOpacity(0.16),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Чаты',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded),
                    label: 'Группы',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.call_outlined),
                    selectedIcon: Icon(Icons.call_rounded),
                    label: 'Звонки',
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

class _GlassFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassFab({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  Color _mutedAccent(ColorScheme cs) {
    return Color.lerp(cs.primary, cs.onSurface, 0.45)!;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _mutedAccent(cs);

    return Padding(
      padding: const EdgeInsets.only(right: 2, bottom: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.62),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.onSurface.withOpacity(0.10)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 26,
                    spreadRadius: -12,
                    offset: const Offset(0, 18),
                    color: Colors.black.withOpacity(0.32),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accent.withOpacity(0.88),
                              accent.withOpacity(0.22),
                            ],
                          ),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(0.08),
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.90),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostedBar extends StatelessWidget {
  final Color tint;
  final Color border;

  const _FrostedBar({
    required this.tint,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            border: Border(
              bottom: BorderSide(color: border),
            ),
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
          colors: [
            accent.withOpacity(0.92),
            accent.withOpacity(0.28),
          ],
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

class _ProfileAvatar extends StatelessWidget {
  final Uint8List? bytes;
  final String initials;
  final Color accent;

  const _ProfileAvatar({
    required this.bytes,
    required this.initials,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.92),
            accent.withOpacity(0.18),
          ],
        ),
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: cs.surface.withOpacity(0.55),
        backgroundImage: bytes == null ? null : MemoryImage(bytes!),
        child: bytes == null
            ? Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface.withOpacity(0.90),
                ),
              )
            : null,
      ),
    );
  }
}

/* ===== вкладки ===== */

class _ChatsTab extends StatelessWidget {
  final List<Contact> contacts;
  final void Function(Contact) onOpenChat;

  const _ChatsTab({
    required this.contacts,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const _StubPanel(
        title: 'Пока нет чатов',
        subtitle:
            'Открой «Настройки» в меню, подключись к XMPP или создай «Новый чат».',
        icon: Icons.chat_bubble_outline_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = contacts[i];
        return _ContactCard(
          contact: c,
          onOpen: () => onOpenChat(c),
          onOpenInfo: () => showContactInfoPopup(context, contact: c),
        );
      },
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onOpen;
  final VoidCallback onOpenInfo;

  const _ContactCard({
    required this.contact,
    required this.onOpen,
    required this.onOpenInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isOnline = (contact.status ?? '').toLowerCase() == 'online';

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
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onOpenInfo,
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
                              Color.lerp(cs.primary, cs.onSurface, 0.45)!
                                  .withOpacity(0.88),
                              Color.lerp(cs.primary, cs.onSurface, 0.45)!
                                  .withOpacity(0.18),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: cs.surface.withOpacity(0.55),
                          child: Text(
                            contact.initials,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                              color: cs.onSurface.withOpacity(0.92),
                            ),
                          ),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.surface.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.08),
                              ),
                            ),
                            child: Text(
                              contact.time ?? '',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.70),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contact.lastMessage ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.70),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            isOnline
                                ? Icons.circle_rounded
                                : Icons.circle_outlined,
                            size: 10,
                            color: isOnline
                                ? Color.lerp(cs.primary, cs.onSurface, 0.45)!
                                    .withOpacity(0.92)
                                : cs.onSurface.withOpacity(0.25),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            contact.status ?? '',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurface.withOpacity(0.62),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              contact.jid,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurface.withOpacity(0.35),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
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

class _ConnectionChip extends StatelessWidget {
  final ConnectionStatus status;
  final String hint;
  final VoidCallback onTap;

  const _ConnectionChip({
    required this.status,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final dot = switch (status) {
      ConnectionStatus.connected => Colors.greenAccent.shade400,
      ConnectionStatus.connecting => Colors.amberAccent.shade200,
      ConnectionStatus.error => cs.error,
      ConnectionStatus.disconnected => cs.onSurface.withOpacity(0.25),
    };

    final icon = status == ConnectionStatus.connected
        ? Icons.logout_rounded
        : Icons.login_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.38),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: cs.onSurface.withOpacity(0.10)),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle_rounded, size: 10, color: dot),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface.withOpacity(0.78),
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(icon, size: 16, color: cs.onSurface.withOpacity(0.55)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallsPanel extends StatelessWidget {
  const _CallsPanel();

  @override
  Widget build(BuildContext context) {
    final calls = context.watch<CallsController>();
    final list = calls.calls;

    if (list.isEmpty) {
      return const _StubPanel(
        title: 'Пока нет звонков',
        subtitle:
            'Звонки здесь — демо-заглушки. Реальный VoIP подключим позже.',
        icon: Icons.call_outlined,
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = list[i];
        final icon = c.isGroup ? Icons.groups_rounded : Icons.person_rounded;
        final arrow =
            c.outgoing ? Icons.call_made_rounded : Icons.call_received_rounded;
        final status = c.missed ? 'Пропущен' : 'Завершён';

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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Звонок (демо): ${c.peerName} • $status')),
                );
              },
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
                        border:
                            Border.all(color: cs.onSurface.withOpacity(0.08)),
                      ),
                      child: Icon(icon, color: cs.onSurface.withOpacity(0.78)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.peerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                arrow,
                                size: 16,
                                color: c.missed
                                    ? Colors.redAccent
                                    : cs.onSurface.withOpacity(0.55),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: cs.onSurface.withOpacity(0.68),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: cs.onSurface.withOpacity(0.08)),
                      ),
                      child: Text(
                        _fmt(c.ts),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.70),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StubPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StubPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

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
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.70),
                        fontWeight: FontWeight.w600,
                        height: 1.25,
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

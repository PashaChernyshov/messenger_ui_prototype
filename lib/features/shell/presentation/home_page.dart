import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_design/app/state/app_state.dart';
import 'package:app_design/features/chat/presentation/chat_screen.dart';
import 'package:app_design/features/contacts/domain/contact.dart';
import 'package:app_design/features/contacts/presentation/contact_info_popup.dart';
import 'package:app_design/features/contacts/presentation/contact_search.dart';
import 'package:app_design/features/groups/presentation/group_list_screen.dart';
import 'package:app_design/features/shell/presentation/menu/app_menu_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  _ChatFilter chatFilter = _ChatFilter.all;

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 980;

  String _tabLabel(int i) => switch (i) {
        0 => '\u0427\u0430\u0442\u044b',
        1 => '\u0413\u0440\u0443\u043f\u043f\u044b',
        _ => '\u0417\u0432\u043e\u043d\u043a\u0438',
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
    final app = context.watch<AppState>();
    final wide = _isWide(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final accent = _mutedAccent(cs);
    final bg = _pageBg(cs);

    Widget body = _buildBody(context, app);

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
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: Colors.transparent),
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
        backgroundColor: cs.surface,
        toolbarHeight: 64,
        flexibleSpace: _FrostedBar(
          tint: cs.surface,
          border: Colors.transparent,
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
                    '\u041c\u0435\u0441\u0441\u0435\u043d\u0434\u0436\u0435\u0440',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
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
          IconButton(
            tooltip: '\u041f\u043e\u0438\u0441\u043a',
            onPressed: () {
              showSearch(
                context: context,
                delegate: ContactSearchDelegate(
                  contacts: app.contacts,
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
                borderRadius: BorderRadius.circular(8),
                side: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _ProfileAvatar(
              bytes: app.profile.avatarBytes,
              initials: _initials(app.profile.name),
              accent: accent,
              onTap: () => showAppMenuSheet(context),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(color: bg),
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
              label: '\u041d\u043e\u0432\u044b\u0439 \u0447\u0430\u0442',
              onTap: () => _createStubChat(context),
            )
          : index == 1
              ? _GlassFab(
                  icon: Icons.group_add_rounded,
                  label:
                      '\u041d\u043e\u0432\u0430\u044f \u0433\u0440\u0443\u043f\u043f\u0430',
                  onTap: () => showAppMenuSheet(context),
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

  Widget _buildBody(BuildContext context, AppState app) {
    if (index == 0) {
      return _ChatsTab(
        app: app,
        filter: chatFilter,
        onFilterChanged: (value) => setState(() => chatFilter = value),
        onOpenChat: _openChat,
      );
    }
    if (index == 1) return const GroupListScreen(embedded: true);
    return const _CallsPanel();
  }

  void _openChat(Contact c) {
    final app = context.read<AppState>();
    app.ensureChatSeed(c.jid, c.displayName);
    app.loadXmppArchiveForPeer(c.jid);

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
    final app = context.read<AppState>();

    final id = Random().nextInt(9999);
    final jid =
        'user$id@${app.xmpp.domain.isEmpty ? "example.com" : app.xmpp.domain}';
    final contact = Contact(
      jid: jid,
      displayName: '\u041a\u043b\u0438\u0435\u043d\u0442 #$id',
      lastMessage:
          '\u0414\u043e\u0431\u0440\u044b\u0439 \u0434\u0435\u043d\u044c! \u0415\u0441\u0442\u044c \u0432\u043e\u043f\u0440\u043e\u0441...',
      time: '\u0441\u0435\u0439\u0447\u0430\u0441',
      status: 'Online',
    );

    app.addContact(contact);
    _openChat(contact);
  }
}

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
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              width: 92,
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: Colors.transparent),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  navigationRailTheme: NavigationRailThemeData(
                    backgroundColor: Colors.transparent,
                    indicatorColor: accent.withOpacity(0.14),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble_outline_rounded),
                      selectedIcon: Icon(Icons.chat_bubble_rounded),
                      label: Text('\u0427\u0430\u0442\u044b'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.groups_outlined),
                      selectedIcon: Icon(Icons.groups_rounded),
                      label: Text('\u0413\u0440\u0443\u043f\u043f\u044b'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.call_outlined),
                      selectedIcon: Icon(Icons.call_rounded),
                      label: Text('\u0417\u0432\u043e\u043d\u043a\u0438'),
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
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: Colors.transparent),
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
                    label: '\u0427\u0430\u0442\u044b',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded),
                    label: '\u0413\u0440\u0443\u043f\u043f\u044b',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.call_outlined),
                    selectedIcon: Icon(Icons.call_rounded),
                    label: '\u0417\u0432\u043e\u043d\u043a\u0438',
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
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    spreadRadius: -10,
                    offset: const Offset(0, 8),
                    color: Colors.black.withOpacity(0.24),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
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
                          borderRadius: BorderRadius.circular(8),
                          color: accent.withOpacity(0.18),
                          border: Border.all(
                            color: Colors.transparent,
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
                          letterSpacing: 0,
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
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
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
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: accent.withOpacity(0.18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.20),
          ),
        ],
        border: Border.all(color: Colors.transparent),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Uint8List? bytes;
  final String initials;
  final Color accent;
  final VoidCallback? onTap;

  const _ProfileAvatar({
    required this.bytes,
    required this.initials,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: '\u041c\u0435\u043d\u044e',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: cs.primary.withOpacity(0.14),
            border: Border.all(color: Colors.transparent),
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
        ),
      ),
    );
  }
}

/* Tabs and cards */

enum _ChatFilter { all, online, unread, archived }

class _ChatsTab extends StatelessWidget {
  final AppState app;
  final _ChatFilter filter;
  final ValueChanged<_ChatFilter> onFilterChanged;
  final void Function(Contact) onOpenChat;

  const _ChatsTab({
    required this.app,
    required this.filter,
    required this.onFilterChanged,
    required this.onOpenChat,
  });

  List<Contact> _filteredContacts() {
    final contacts = app.visibleContacts(
      includeArchived: filter == _ChatFilter.archived,
    );

    return switch (filter) {
      _ChatFilter.all => contacts,
      _ChatFilter.online => contacts
          .where((contact) => (contact.status ?? '').toLowerCase() == 'online')
          .toList(),
      _ChatFilter.unread => contacts
          .where((contact) => app.unreadPeers.contains(contact.jid))
          .toList(),
      _ChatFilter.archived => contacts
          .where((contact) => app.archivedPeers.contains(contact.jid))
          .toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filteredContacts();

    if (contacts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
        children: [
          _ChatFilterBar(
            value: filter,
            onChanged: onFilterChanged,
          ),
          const SizedBox(height: 10),
          const _StubPanel(
            title:
                '\u041f\u043e\u043a\u0430 \u043d\u0435\u0442 \u0447\u0430\u0442\u043e\u0432',
            subtitle:
                '\u041f\u0440\u043e\u0432\u0435\u0440\u044c \u0444\u0438\u043b\u044c\u0442\u0440, \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u0435 \u0438\u043b\u0438 \u0441\u043e\u0437\u0434\u0430\u0439 \u043d\u043e\u0432\u044b\u0439 \u0447\u0430\u0442.',
            icon: Icons.chat_bubble_outline_rounded,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
      itemCount: contacts.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) {
          return _ChatFilterBar(
            value: filter,
            onChanged: onFilterChanged,
          );
        }

        final contact = contacts[i - 1];
        return _ContactCard(
          contact: contact,
          pinned: app.pinnedPeers.contains(contact.jid),
          archived: app.archivedPeers.contains(contact.jid),
          unread: app.unreadPeers.contains(contact.jid),
          onOpen: () => onOpenChat(contact),
          onOpenInfo: () => showContactInfoPopup(context, contact: contact),
          onTogglePinned: () => app.togglePinned(contact.jid),
          onToggleArchived: () => app.toggleArchived(contact.jid),
          onMarkUnread: () => app.markUnread(contact.jid),
        );
      },
    );
  }
}

class _ChatFilterBar extends StatefulWidget {
  final _ChatFilter value;
  final ValueChanged<_ChatFilter> onChanged;

  const _ChatFilterBar({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ChatFilterBar> createState() => _ChatFilterBarState();
}

class _ChatFilterBarState extends State<_ChatFilterBar> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;

  String get _label => switch (widget.value) {
        _ChatFilter.all => '\u0412\u0441\u0435 \u0447\u0430\u0442\u044b',
        _ChatFilter.online => '\u041e\u043d\u043b\u0430\u0439\u043d',
        _ChatFilter.unread =>
          '\u041d\u0435\u043f\u0440\u043e\u0447\u0438\u0442\u0430\u043d\u043d\u044b\u0435',
        _ChatFilter.archived => '\u0410\u0440\u0445\u0438\u0432',
      };

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleOverlay() {
    if (_entry == null) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 220;

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 42),
              child: _FilterPopup(
                width: width.clamp(220, 280).toDouble(),
                value: widget.value,
                onSelect: (value) {
                  _removeOverlay();
                  widget.onChanged(value);
                },
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  void _removeOverlay() {
    final hadEntry = _entry != null;
    _entry?.remove();
    _entry = null;
    if (hadEntry && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.58),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _toggleOverlay,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: cs.onSurface.withOpacity(0.66),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurface.withOpacity(0.82),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _entry == null
                          ? Icons.expand_more_rounded
                          : Icons.expand_less_rounded,
                      size: 18,
                      color: cs.onSurface.withOpacity(0.46),
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

class _FilterPopup extends StatelessWidget {
  final double width;
  final _ChatFilter value;
  final ValueChanged<_ChatFilter> onSelect;

  const _FilterPopup({
    required this.width,
    required this.value,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: -8,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.34),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterPopupAction(
                icon: Icons.forum_rounded,
                title: '\u0412\u0441\u0435 \u0447\u0430\u0442\u044b',
                selected: value == _ChatFilter.all,
                onTap: () => onSelect(_ChatFilter.all),
              ),
              _FilterPopupAction(
                icon: Icons.circle_rounded,
                title: '\u041e\u043d\u043b\u0430\u0439\u043d',
                selected: value == _ChatFilter.online,
                onTap: () => onSelect(_ChatFilter.online),
              ),
              _FilterPopupAction(
                icon: Icons.mark_chat_unread_rounded,
                title:
                    '\u041d\u0435\u043f\u0440\u043e\u0447\u0438\u0442\u0430\u043d\u043d\u044b\u0435',
                selected: value == _ChatFilter.unread,
                onTap: () => onSelect(_ChatFilter.unread),
              ),
              _FilterPopupAction(
                icon: Icons.archive_rounded,
                title: '\u0410\u0440\u0445\u0438\u0432',
                selected: value == _ChatFilter.archived,
                onTap: () => onSelect(_ChatFilter.archived),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPopupAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPopupAction({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = Color.lerp(cs.primary, cs.onSurface, 0.45)!;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? cs.onSurface.withOpacity(0.90)
                      : cs.onSurface.withOpacity(0.58),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.86),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: cs.onSurface.withOpacity(0.68),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactActionsButton extends StatefulWidget {
  final String contactName;
  final bool pinned;
  final bool archived;
  final VoidCallback onTogglePinned;
  final VoidCallback onToggleArchived;
  final VoidCallback onMarkUnread;
  final VoidCallback onOpenInfo;

  const _ContactActionsButton({
    required this.contactName,
    required this.pinned,
    required this.archived,
    required this.onTogglePinned,
    required this.onToggleArchived,
    required this.onMarkUnread,
    required this.onOpenInfo,
  });

  @override
  State<_ContactActionsButton> createState() => _ContactActionsButtonState();
}

class _ContactActionsButtonState extends State<_ContactActionsButton> {
  static const double _popupWidth = 280;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleOverlay() {
    if (_entry == null) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-236, 42),
              child: _ContactActionsPopup(
                width: _popupWidth,
                contactName: widget.contactName,
                pinned: widget.pinned,
                archived: widget.archived,
                onPick: (action) {
                  _removeOverlay();
                  switch (action) {
                    case _ContactAction.pin:
                      widget.onTogglePinned();
                    case _ContactAction.archive:
                      widget.onToggleArchived();
                    case _ContactAction.unread:
                      widget.onMarkUnread();
                    case _ContactAction.info:
                      widget.onOpenInfo();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  void _removeOverlay() {
    final hadEntry = _entry != null;
    _entry?.remove();
    _entry = null;
    if (hadEntry && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        tooltip: '\u0414\u0435\u0439\u0441\u0442\u0432\u0438\u044f',
        onPressed: _toggleOverlay,
        icon: Icon(
          Icons.more_horiz_rounded,
          color: _entry == null
              ? cs.onSurface.withOpacity(0.55)
              : cs.onSurface.withOpacity(0.88),
        ),
      ),
    );
  }
}

enum _ContactAction { pin, archive, unread, info }

class _ContactActionsPopup extends StatelessWidget {
  final double width;
  final String contactName;
  final bool pinned;
  final bool archived;
  final ValueChanged<_ContactAction> onPick;

  const _ContactActionsPopup({
    required this.width,
    required this.contactName,
    required this.pinned,
    required this.archived,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: -8,
                offset: const Offset(0, 14),
                color: Colors.black.withOpacity(0.34),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Text(
                  contactName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurface.withOpacity(0.62),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _FilterPopupAction(
                icon: Icons.push_pin_rounded,
                title: pinned
                    ? '\u041e\u0442\u043a\u0440\u0435\u043f\u0438\u0442\u044c'
                    : '\u0417\u0430\u043a\u0440\u0435\u043f\u0438\u0442\u044c',
                selected: false,
                onTap: () => onPick(_ContactAction.pin),
              ),
              _FilterPopupAction(
                icon: Icons.archive_rounded,
                title: archived
                    ? '\u0412\u0435\u0440\u043d\u0443\u0442\u044c \u0438\u0437 \u0430\u0440\u0445\u0438\u0432\u0430'
                    : '\u0412 \u0430\u0440\u0445\u0438\u0432',
                selected: false,
                onTap: () => onPick(_ContactAction.archive),
              ),
              _FilterPopupAction(
                icon: Icons.mark_chat_unread_rounded,
                title:
                    '\u041f\u043e\u043c\u0435\u0442\u0438\u0442\u044c \u043d\u0435\u043f\u0440\u043e\u0447\u0438\u0442\u0430\u043d\u043d\u044b\u043c',
                selected: false,
                onTap: () => onPick(_ContactAction.unread),
              ),
              _FilterPopupAction(
                icon: Icons.badge_rounded,
                title:
                    '\u041f\u0440\u043e\u0444\u0438\u043b\u044c \u043a\u043e\u043d\u0442\u0430\u043a\u0442\u0430',
                selected: false,
                onTap: () => onPick(_ContactAction.info),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final bool pinned;
  final bool archived;
  final bool unread;
  final VoidCallback onOpen;
  final VoidCallback onOpenInfo;
  final VoidCallback onTogglePinned;
  final VoidCallback onToggleArchived;
  final VoidCallback onMarkUnread;

  const _ContactCard({
    required this.contact,
    required this.pinned,
    required this.archived,
    required this.unread,
    required this.onOpen,
    required this.onOpenInfo,
    required this.onTogglePinned,
    required this.onToggleArchived,
    required this.onMarkUnread,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final app = context.watch<AppState>();
    final isOnline = (contact.status ?? '').toLowerCase() == 'online';

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              spreadRadius: -10,
              offset: const Offset(0, 14),
              color: Colors.black.withOpacity(0.25),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
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
                          color: cs.primary.withOpacity(0.14),
                          border: Border.all(color: Colors.transparent),
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
                          if (pinned) ...[
                            Icon(
                              Icons.push_pin_rounded,
                              size: 16,
                              color: cs.onSurface.withOpacity(0.62),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (unread) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              contact.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.transparent),
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
                          _ContactActionsButton(
                            contactName: contact.displayName,
                            pinned: pinned,
                            archived: archived,
                            onTogglePinned: onTogglePinned,
                            onToggleArchived: onToggleArchived,
                            onMarkUnread: onMarkUnread,
                            onOpenInfo: onOpenInfo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contact.lastMessage ?? '-',
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
                          if (archived) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.archive_rounded,
                              size: 15,
                              color: cs.onSurface.withOpacity(0.36),
                            ),
                          ],
                          if (app.messageDisplay.showTechnicalIds) ...[
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
                        ],
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

class _CallsPanel extends StatelessWidget {
  const _CallsPanel();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.calls;

    if (list.isEmpty) {
      return const _StubPanel(
        title:
            '\u041f\u043e\u043a\u0430 \u043d\u0435\u0442 \u0437\u0432\u043e\u043d\u043a\u043e\u0432',
        subtitle:
            '\u0417\u0432\u043e\u043d\u043a\u0438 \u0437\u0434\u0435\u0441\u044c \u043f\u043e\u043a\u0430 \u0434\u0435\u043c\u043e\u043d\u0441\u0442\u0440\u0430\u0446\u0438\u043e\u043d\u043d\u044b\u0435. \u0420\u0435\u0430\u043b\u044c\u043d\u044b\u0439 VoIP \u043f\u043e\u0434\u043a\u043b\u044e\u0447\u0438\u043c \u043f\u043e\u0437\u0436\u0435.',
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
        final call = list[i];
        final icon = call.isGroup ? Icons.groups_rounded : Icons.person_rounded;
        final arrow = call.outgoing
            ? Icons.call_made_rounded
            : Icons.call_received_rounded;
        final status = call.missed
            ? '\u041f\u0440\u043e\u043f\u0443\u0449\u0435\u043d'
            : '\u0417\u0430\u0432\u0435\u0440\u0448\u0435\u043d';

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.transparent),
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
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '\u0417\u0432\u043e\u043d\u043e\u043a (\u0434\u0435\u043c\u043e): ${call.peerName} - $status',
                    ),
                  ),
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
                        borderRadius: BorderRadius.circular(8),
                        color: cs.surface.withOpacity(0.40),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Icon(icon, color: cs.onSurface.withOpacity(0.78)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            call.peerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                arrow,
                                size: 16,
                                color: call.missed
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
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Text(
                        _fmt(call.ts),
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: Colors.transparent),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: cs.primary.withOpacity(0.14),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
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
    );
  }
}

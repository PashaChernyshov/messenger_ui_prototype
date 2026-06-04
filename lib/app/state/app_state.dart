import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:app_design/features/contacts/domain/contact.dart';
import 'package:app_design/features/groups/domain/group.dart';
import 'package:app_design/features/calls/domain/call_entry.dart';
import 'package:app_design/features/chat/domain/chat_message.dart';
import 'package:app_design/features/xmpp/domain/connection_status.dart';
import 'package:app_design/features/xmpp/domain/xmpp_bookmark.dart';
import 'package:app_design/features/xmpp/domain/xmpp_chat_message.dart';
import 'package:app_design/features/xmpp/domain/xmpp_room_presence.dart';
import 'package:app_design/features/profile/domain/profile_data.dart';
import 'package:app_design/features/calls/data/call_history_repository.dart';
import 'package:app_design/features/chat/data/chat_repository.dart';
import 'package:app_design/features/groups/data/group_repository.dart';
import 'package:app_design/features/profile/data/profile_repository.dart';
import 'package:app_design/features/settings/data/ui_settings_repository.dart';
import 'package:app_design/features/settings/domain/message_display_settings.dart';
import 'package:app_design/app/theme/app_theme_factory.dart';
import 'package:app_design/features/xmpp/data/xmpp_service.dart';

export 'package:app_design/features/calls/domain/call_entry.dart';
export 'package:app_design/features/chat/domain/chat_message.dart';
export 'package:app_design/features/xmpp/domain/connection_status.dart';
export 'package:app_design/features/profile/domain/profile_data.dart';
export 'package:app_design/features/settings/domain/message_display_settings.dart';

class AppState extends ChangeNotifier {
  AppState({
    XmppService? xmppService,
    UiSettingsRepository? settingsRepository,
    ProfileRepository? profileRepository,
    GroupRepository? groupRepository,
    ChatRepository? chatRepository,
    CallHistoryRepository? callHistoryRepository,
    AppThemeFactory? themeFactory,
  })  : xmpp = xmppService ?? XmppService.instance,
        _settingsRepository =
            settingsRepository ?? SharedPrefsUiSettingsRepository(),
        _profileRepository =
            profileRepository ?? SharedPrefsProfileRepository(),
        _groupRepository = groupRepository ?? SharedPrefsGroupRepository(),
        _chatRepository = chatRepository ?? InMemoryChatRepository(),
        _callHistoryRepository =
            callHistoryRepository ?? DemoCallHistoryRepository(),
        _themeFactory = themeFactory ?? const AppThemeFactory();

  final XmppService xmpp;
  final UiSettingsRepository _settingsRepository;
  final ProfileRepository _profileRepository;
  final GroupRepository _groupRepository;
  final ChatRepository _chatRepository;
  final CallHistoryRepository _callHistoryRepository;
  final AppThemeFactory _themeFactory;
  StreamSubscription<XmppChatMessage>? _incomingSubscription;
  StreamSubscription<XmppRoomPresence>? _roomPresenceSubscription;

  double fontSize = 14;
  MessageDisplaySettings messageDisplay = MessageDisplaySettings.defaults;
  String? selectedMicrophoneId;
  Set<String> favoriteReactions =
      SharedPrefsUiSettingsRepository.defaultFavoriteReactions;
  ProfileData profile = const ProfileData(
    name: 'User',
    phone: '',
    status: 'Available',
    avatarBytes: null,
  );

  ConnectionStatus connection = ConnectionStatus.disconnected;
  String connectionHint = '';
  String xmppSyncHint = '';

  List<Contact> contacts = const [];
  List<Group> groups = const [];
  List<CallEntry> calls = const [];
  final Set<String> pinnedPeers = {};
  final Set<String> archivedPeers = {};
  final Map<String, String> drafts = {};
  final Set<String> unreadPeers = {};

  ThemeData get themeData => _themeFactory.build(fontSize);

  Future<void> bootstrap() async {
    fontSize = await _settingsRepository.loadFontSize();
    messageDisplay = await _settingsRepository.loadMessageDisplaySettings();
    selectedMicrophoneId = await _settingsRepository.loadSelectedMicrophoneId();
    favoriteReactions = await _settingsRepository.loadFavoriteReactions();
    profile = await _profileRepository.load();
    groups = await _groupRepository.load();
    calls = _callHistoryRepository.loadDemoCalls();

    xmpp.roster.addListener(_onRosterChanged);
    xmpp.connectionState.addListener(_onConnectionChanged);
    _incomingSubscription = xmpp.incomingMessages.listen(_onIncomingMessage);
    _roomPresenceSubscription =
        xmpp.roomPresences.listen(_onRoomPresenceChanged);
    await xmpp.loadConfig();

    notifyListeners();
  }

  void disposeState() {
    xmpp.roster.removeListener(_onRosterChanged);
    xmpp.connectionState.removeListener(_onConnectionChanged);
    _incomingSubscription?.cancel();
    _roomPresenceSubscription?.cancel();
  }

  Future<void> setFontSize(double value) async {
    fontSize = value;
    await _settingsRepository.saveFontSize(value);
    notifyListeners();
  }

  Future<void> updateMessageDisplay(MessageDisplaySettings value) async {
    messageDisplay = value;
    await _settingsRepository.saveMessageDisplaySettings(value);
    notifyListeners();
  }

  Future<void> updateSelectedMicrophoneId(String? value) async {
    selectedMicrophoneId = value;
    await _settingsRepository.saveSelectedMicrophoneId(value);
    notifyListeners();
  }

  Future<void> toggleFavoriteReaction(String emoji) async {
    final next = Set<String>.from(favoriteReactions);
    if (next.contains(emoji)) {
      next.remove(emoji);
    } else {
      next.add(emoji);
    }
    favoriteReactions = next;
    await _settingsRepository.saveFavoriteReactions(next);
    notifyListeners();
  }

  Future<void> updateProfile(ProfileData next) async {
    profile = next;
    await _profileRepository.save(next);
    notifyListeners();
  }

  void addContact(Contact contact) {
    contacts = [contact, ...contacts];
    notifyListeners();
  }

  List<Contact> visibleContacts({bool includeArchived = false}) {
    final list = includeArchived
        ? contacts
        : contacts.where((contact) => !archivedPeers.contains(contact.jid));
    final sorted = list.toList()
      ..sort((a, b) {
        final aPinned = pinnedPeers.contains(a.jid);
        final bPinned = pinnedPeers.contains(b.jid);
        if (aPinned != bPinned) return aPinned ? -1 : 1;
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });
    return sorted;
  }

  List<ChatMessage> chatOf(String peerKey) =>
      _chatRepository.messagesOf(peerKey);

  void ensureChatSeed(String peerKey, String displayName) {
    if (xmpp.connectionState.value == XmppConnectionState.connected) return;
    _chatRepository.seedIfEmpty(peerKey, displayName);
  }

  String draftOf(String peerKey) => drafts[peerKey] ?? '';

  void updateDraft(String peerKey, String value) {
    if (value.trim().isEmpty) {
      drafts.remove(peerKey);
    } else {
      drafts[peerKey] = value;
    }
    notifyListeners();
  }

  void clearDraft(String peerKey) {
    drafts.remove(peerKey);
    notifyListeners();
  }

  void togglePinned(String peerKey) {
    pinnedPeers.contains(peerKey)
        ? pinnedPeers.remove(peerKey)
        : pinnedPeers.add(peerKey);
    notifyListeners();
  }

  void toggleArchived(String peerKey) {
    archivedPeers.contains(peerKey)
        ? archivedPeers.remove(peerKey)
        : archivedPeers.add(peerKey);
    notifyListeners();
  }

  void markUnread(String peerKey) {
    if (unreadPeers.add(peerKey)) {
      notifyListeners();
    }
  }

  void markRead(String peerKey) {
    if (unreadPeers.remove(peerKey)) {
      notifyListeners();
    }
  }

  void clearChat(String peerKey) {
    _chatRepository.clear(peerKey);
    notifyListeners();
  }

  void deleteMessage(String peerKey, String messageId) {
    _chatRepository.deleteMessage(peerKey, messageId);
    notifyListeners();
  }

  void setReaction(String peerKey, String messageId, String? reaction) {
    _chatRepository.setReaction(peerKey, messageId, reaction);
    notifyListeners();
  }

  void setMessageTaskStatus(
    String peerKey,
    String messageId,
    MessageTaskStatus? status,
  ) {
    _chatRepository.setTaskStatus(peerKey, messageId, status);
    notifyListeners();
  }

  void setMessagePinned(String peerKey, String messageId, bool pinned) {
    _chatRepository.setPinned(peerKey, messageId, pinned);
    notifyListeners();
  }

  void addLocalMessage(String peerKey, ChatMessage message) {
    _chatRepository.addMessage(peerKey, message);
    notifyListeners();
  }

  String addPendingMediaMessage({
    required String peerKey,
    required ChatMediaKind kind,
    required Duration duration,
    String? replyToMessageId,
    String? replyToText,
  }) {
    final message = _chatRepository.addPendingMedia(
      peerKey: peerKey,
      kind: kind,
      duration: duration,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    drafts.remove(peerKey);
    unreadPeers.remove(peerKey);
    notifyListeners();
    return message.id;
  }

  void updateMediaProgress(
    String peerKey,
    String messageId, {
    required double progress,
    required String status,
  }) {
    _chatRepository.updateMediaProgress(
      peerKey,
      messageId,
      progress: progress,
      status: status,
    );
    notifyListeners();
  }

  void failMediaMessage(String peerKey, String messageId, String status) {
    _chatRepository.failMediaMessage(peerKey, messageId, status);
    notifyListeners();
  }

  Future<void> completePendingVoiceMessage({
    required String peerKey,
    required String messageId,
    required String path,
    required Duration duration,
  }) async {
    final current = _chatRepository.messagesOf(peerKey).firstWhere(
          (message) => message.id == messageId,
          orElse: () => ChatMessage(
            id: messageId,
            from: 'me',
            text: '',
            ts: DateTime.now(),
          ),
        );
    _chatRepository.updateMessage(
      peerKey,
      messageId,
      current.copyWith(
        voicePath: path,
        voiceDuration: duration,
        mediaProgress: 0.95,
        status: 'отправка',
      ),
    );
    notifyListeners();

    final seconds = duration.inSeconds.clamp(1, 599);
    await _sendXmppNotice(peerKey, '[Голосовое сообщение] $secondsс');
    _chatRepository.updateMessage(
      peerKey,
      messageId,
      current.copyWith(
        voicePath: path,
        voiceDuration: duration,
        mediaProgress: 1,
        status: 'отправлено',
        clearMediaProgress: true,
      ),
    );
    notifyListeners();
  }

  Future<void> completePendingVideoCircleMessage({
    required String peerKey,
    required String messageId,
    required String path,
    required Duration duration,
    required bool mirrorHorizontally,
  }) async {
    final current = _chatRepository.messagesOf(peerKey).firstWhere(
          (message) => message.id == messageId,
          orElse: () => ChatMessage(
            id: messageId,
            from: 'me',
            text: '',
            ts: DateTime.now(),
          ),
        );
    _chatRepository.updateMessage(
      peerKey,
      messageId,
      current.copyWith(
        videoPath: path,
        videoDuration: duration,
        videoMirrorHorizontally: mirrorHorizontally,
        mediaProgress: 0.95,
        status: 'отправка',
      ),
    );
    notifyListeners();

    final seconds = duration.inSeconds.clamp(1, 599);
    await _sendXmppNotice(peerKey, '[Видео-кружок] $secondsс');
    _chatRepository.updateMessage(
      peerKey,
      messageId,
      current.copyWith(
        videoPath: path,
        videoDuration: duration,
        videoMirrorHorizontally: mirrorHorizontally,
        mediaProgress: 1,
        status: 'отправлено',
        clearMediaProgress: true,
      ),
    );
    notifyListeners();
  }

  Future<void> connect() async {
    await xmpp.connectAndLoadRoster();
    if (xmpp.connectionState.value == XmppConnectionState.connected) {
      xmppSyncHint = '';
      final bookmarkCount = await loadXmppBookmarks();
      await loadXmppRecentArchive();
      await loadXmppArchivesForRoster();
      final rosterCount = contacts.length;
      final chatCount = contacts.where((contact) {
        return _chatRepository.messagesOf(contact.jid).isNotEmpty;
      }).length;
      final groupChatCount = groups.where((group) {
        return _chatRepository.messagesOf(groupPeerKey(group.id)).isNotEmpty;
      }).length;
      xmppSyncHint =
          '\u041a\u043e\u043d\u0442\u0430\u043a\u0442\u044b: $rosterCount, \u043b\u0438\u0447\u043d\u044b\u0435 \u0447\u0430\u0442\u044b: $chatCount, \u0433\u0440\u0443\u043f\u043f\u044b: $bookmarkCount, \u0433\u0440\u0443\u043f\u043f\u044b \u0441 \u0438\u0441\u0442\u043e\u0440\u0438\u0435\u0439: $groupChatCount';
      connectionHint = xmppSyncHint;
      notifyListeners();
    }
  }

  Future<void> disconnect() async => xmpp.disconnect();

  Future<void> loadXmppArchivesForRoster() async {
    final rosterSnapshot = List<Contact>.from(contacts);
    for (final contact in rosterSnapshot) {
      await loadXmppArchiveForPeer(contact.jid);
    }
  }

  Future<int> loadXmppBookmarks() async {
    if (xmpp.connectionState.value != XmppConnectionState.connected) return 0;
    final bookmarks = await xmpp.fetchBookmarks();
    if (bookmarks.isEmpty) return 0;

    final existingIds = groups.map((group) => group.id).toSet();
    final imported = <Group>[];
    for (final bookmark in bookmarks) {
      if (existingIds.contains(bookmark.jid)) continue;
      imported.add(_groupFromBookmark(bookmark));
    }
    if (imported.isNotEmpty) {
      groups = [...imported, ...groups];
      await _groupRepository.save(groups);
      notifyListeners();
    }
    for (final bookmark in bookmarks) {
      await xmpp.joinRoom(bookmark.jid, nick: bookmark.nick);
      await loadXmppArchiveForGroup(bookmark.jid);
    }
    return bookmarks.length;
  }

  Future<void> loadXmppRecentArchive() async {
    if (xmpp.connectionState.value != XmppConnectionState.connected) return;
    final archived = await xmpp.fetchRecentArchive();
    if (archived.isEmpty) return;

    final byPeer = <String, List<XmppChatMessage>>{};
    for (final message in archived) {
      if (message.peerJid.isEmpty) continue;
      final peerKey =
          message.groupChat ? groupPeerKey(message.peerJid) : message.peerJid;
      byPeer.putIfAbsent(peerKey, () => []).add(message);
    }

    for (final entry in byPeer.entries) {
      final sample = entry.value.first;
      if (sample.groupChat) {
        _ensureGroupForRoom(sample.peerJid);
      } else {
        _ensureContactForPeer(entry.key);
      }
      _chatRepository.addMessages(
        entry.key,
        entry.value.map(_fromXmppMessage),
      );
      if (!sample.groupChat) _updateContactPreview(entry.key);
    }
    notifyListeners();
  }

  Future<void> loadXmppArchiveForPeer(String peerJid) async {
    if (xmpp.connectionState.value != XmppConnectionState.connected) return;
    final archived = await xmpp.fetchChatArchive(peerJid);
    if (archived.isEmpty) return;
    _chatRepository.addMessages(
      peerJid,
      archived.map(_fromXmppMessage),
    );
    _updateContactPreview(peerJid);
    notifyListeners();
  }

  Future<void> loadXmppArchiveForGroup(String roomJid) async {
    if (xmpp.connectionState.value != XmppConnectionState.connected) return;
    final room = roomJid.trim();
    if (room.isEmpty) return;

    final archived = await xmpp.fetchRoomArchive(room);
    if (archived.isEmpty) return;
    final peerKey = groupPeerKey(room);
    _chatRepository.addMessages(
      peerKey,
      archived.map(_fromXmppMessage),
    );
    notifyListeners();
  }

  Future<void> activateXmppRoom(String roomJid) async {
    if (xmpp.connectionState.value != XmppConnectionState.connected) return;
    if (!_looksLikeJid(roomJid)) return;
    await xmpp.joinRoom(roomJid);
    await loadXmppArchiveForGroup(roomJid);
  }

  Future<void> sendText(
    String toJid,
    String text, {
    String? replyToMessageId,
    String? replyToText,
  }) async {
    _chatRepository.addText(
      peerKey: toJid,
      from: 'me',
      text: text,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    drafts.remove(toJid);
    unreadPeers.remove(toJid);
    notifyListeners();
    await _sendXmppNotice(toJid, text);
  }

  Future<void> sendAttachment({
    required String toJid,
    required String caption,
    required Uint8List bytes,
    required String name,
    required String mime,
    String? replyToMessageId,
    String? replyToText,
  }) async {
    _chatRepository.addAttachment(
      peerKey: toJid,
      from: 'me',
      text: caption,
      bytes: bytes,
      name: name,
      mime: mime,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    drafts.remove(toJid);
    notifyListeners();

    final notifyText = [
      if (caption.isNotEmpty) caption,
      '[\u0412\u043b\u043e\u0436\u0435\u043d\u0438\u0435] $name (${(bytes.length / 1024).toStringAsFixed(0)} KB)',
    ].join('\n');

    await _sendXmppNotice(toJid, notifyText);
  }

  Future<void> sendVoiceMessage({
    required String toJid,
    required String path,
    required Duration duration,
    String? replyToMessageId,
    String? replyToText,
  }) async {
    _chatRepository.addVoice(
      peerKey: toJid,
      from: 'me',
      path: path,
      duration: duration,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    drafts.remove(toJid);
    notifyListeners();

    final seconds = duration.inSeconds.clamp(1, 599);
    await _sendXmppNotice(toJid, '[Голосовое сообщение] $secondsс');
  }

  Future<void> sendVideoCircle({
    required String toJid,
    required String path,
    required Duration duration,
    bool mirrorHorizontally = false,
    String? replyToMessageId,
    String? replyToText,
  }) async {
    _chatRepository.addVideoCircle(
      peerKey: toJid,
      from: 'me',
      path: path,
      duration: duration,
      mirrorHorizontally: mirrorHorizontally,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
    );
    drafts.remove(toJid);
    notifyListeners();

    final seconds = duration.inSeconds.clamp(1, 599);
    await _sendXmppNotice(toJid, '[Видео-кружок] $secondsс');
  }

  Future<void> forwardMessage({
    required String toPeerKey,
    required ChatMessage source,
    required String forwardedFrom,
  }) async {
    _chatRepository.forwardMessage(
      peerKey: toPeerKey,
      source: source,
      forwardedFrom: forwardedFrom,
    );
    unreadPeers.remove(toPeerKey);
    notifyListeners();
    final notice = _forwardNoticeText(source);
    if (toPeerKey.startsWith('group:')) {
      final roomJid = toPeerKey.substring('group:'.length);
      if (xmpp.connectionState.value == XmppConnectionState.connected &&
          _looksLikeJid(roomJid)) {
        await xmpp.sendGroupMessage(roomJid, notice);
      }
      return;
    }
    await _sendXmppNotice(toPeerKey, notice);
  }

  String _forwardNoticeText(ChatMessage source) {
    final content = source.text.trim();
    if (content.isNotEmpty) return content;
    if (source.attachmentName != null) {
      return '[Вложение] ${source.attachmentName}';
    }
    if (source.voicePath != null) return '[Голосовое сообщение]';
    if (source.videoPath != null) return '[Видео-кружок]';
    return '[Пересланное сообщение]';
  }

  Future<void> _sendXmppNotice(String toJid, String text) async {
    if (xmpp.connectionState.value != XmppConnectionState.connected) {
      connectionHint = 'Локально: XMPP не подключен';
      notifyListeners();
      return;
    }
    try {
      await xmpp.sendMessage(toJid, text);
    } catch (e) {
      connectionHint = 'Локально: не удалось отправить в XMPP';
      notifyListeners();
    }
  }

  Future<void> sendGroupLocal(String groupId, String text) async {
    final peerKey = groupPeerKey(groupId);
    _chatRepository.addText(
      peerKey: peerKey,
      from: 'me',
      text: text,
    );
    drafts.remove(peerKey);
    notifyListeners();
    if (xmpp.connectionState.value == XmppConnectionState.connected &&
        _looksLikeJid(groupId)) {
      await xmpp.sendGroupMessage(groupId, text);
    }
  }

  String groupPeerKey(String groupId) => _chatRepository.groupPeerKey(groupId);

  Future<void> saveGroups() async => _groupRepository.save(groups);

  Future<Group> createGroup({
    required String name,
    required List<String> memberJids,
  }) async {
    groups = await _groupRepository.create(
      current: groups,
      name: name,
      memberJids: memberJids,
    );
    notifyListeners();
    return groups.first;
  }

  Future<void> deleteGroup(String groupId) async {
    groups = await _groupRepository.delete(current: groups, groupId: groupId);
    notifyListeners();
  }

  Group? findGroup(String groupId) {
    for (final group in groups) {
      if (group.id == groupId) return group;
    }
    return null;
  }

  void _onRosterChanged() {
    contacts = List<Contact>.from(xmpp.roster.value);
    notifyListeners();
  }

  void _onIncomingMessage(XmppChatMessage message) {
    final peer = message.peerJid;
    if (peer.isEmpty) return;

    if (message.groupChat) {
      if (message.outgoing) return;
      _ensureGroupForRoom(peer);
      final peerKey = groupPeerKey(peer);
      _chatRepository.addMessage(peerKey, _fromXmppMessage(message));
      unreadPeers.add(peerKey);
    } else {
      _chatRepository.addMessage(peer, _fromXmppMessage(message));
      _ensureContactForPeer(peer);
      _updateContactPreview(peer);
      if (!message.outgoing) unreadPeers.add(peer);
    }
    notifyListeners();
  }

  Future<void> _onRoomPresenceChanged(XmppRoomPresence presence) async {
    if (presence.roomJid.isEmpty || presence.participantId.isEmpty) return;

    _ensureGroupForRoom(presence.roomJid);
    if (_looksLikeJid(presence.participantId) &&
        !_sameBareJid(presence.participantId, xmpp.username)) {
      _ensureContactForPeer(presence.participantId);
      _setContactStatus(
        presence.participantId,
        presence.available ? 'Online' : 'Offline',
      );
    }
    var changed = false;
    groups = groups.map((group) {
      if (group.id != presence.roomJid) return group;
      final members = group.memberJids.toSet();
      if (presence.available) {
        changed = members.add(presence.participantId) || changed;
      } else {
        changed = members.remove(presence.participantId) || changed;
      }
      return group.copyWith(memberJids: members.toList()..sort());
    }).toList();

    if (!changed) return;
    await _groupRepository.save(groups);
    notifyListeners();
  }

  ChatMessage _fromXmppMessage(XmppChatMessage message) {
    return ChatMessage(
      id: message.id,
      from: message.outgoing ? 'me' : message.fromJid,
      text: message.body,
      ts: message.timestamp,
      status: message.archived
          ? '\u0438\u0441\u0442\u043e\u0440\u0438\u044f'
          : '\u043f\u043e\u043b\u0443\u0447\u0435\u043d\u043e',
    );
  }

  Group _groupFromBookmark(XmppBookmark bookmark) {
    return Group(
      id: bookmark.jid,
      name: bookmark.name,
      memberJids: const [],
      createdAt: DateTime.now(),
    );
  }

  void _ensureGroupForRoom(String roomJid) {
    if (groups.any((group) => group.id == roomJid)) return;
    groups = [
      Group(
        id: roomJid,
        name: _displayNameFromJid(roomJid),
        memberJids: const [],
        createdAt: DateTime.now(),
      ),
      ...groups,
    ];
    _groupRepository.save(groups);
  }

  void _ensureContactForPeer(String peerJid) {
    if (contacts.any((contact) => contact.jid == peerJid)) return;
    contacts = [
      Contact(
        jid: peerJid,
        displayName: _displayNameFromJid(peerJid),
        status: 'Offline',
      ),
      ...contacts,
    ];
  }

  void _updateContactPreview(String peerJid) {
    final messages = _chatRepository.messagesOf(peerJid);
    if (messages.isEmpty) return;
    final last = messages.last;
    contacts = contacts
        .map(
          (contact) => contact.jid == peerJid
              ? Contact(
                  jid: contact.jid,
                  displayName: contact.displayName,
                  lastMessage: last.text,
                  time: _formatPreviewTime(last.ts),
                  avatarUrl: contact.avatarUrl,
                  status: contact.status,
                )
              : contact,
        )
        .toList();
  }

  String _displayNameFromJid(String jid) {
    final at = jid.indexOf('@');
    return at == -1 ? jid : jid.substring(0, at);
  }

  bool _looksLikeJid(String value) => value.contains('@');

  bool _sameBareJid(String a, String b) => _bareJid(a) == _bareJid(b);

  String _bareJid(String jid) {
    final slash = jid.indexOf('/');
    return (slash == -1 ? jid : jid.substring(0, slash)).trim();
  }

  void _setContactStatus(String peerJid, String status) {
    contacts = contacts
        .map(
          (contact) => contact.jid == peerJid
              ? Contact(
                  jid: contact.jid,
                  displayName: contact.displayName,
                  lastMessage: contact.lastMessage,
                  time: contact.time,
                  avatarUrl: contact.avatarUrl,
                  status: status,
                )
              : contact,
        )
        .toList();
  }

  String _formatPreviewTime(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _onConnectionChanged() {
    switch (xmpp.connectionState.value) {
      case XmppConnectionState.disconnected:
        connection = ConnectionStatus.disconnected;
        connectionHint =
            '\u041e\u0442\u043a\u043b\u044e\u0447\u0435\u043d\u043e';
        break;
      case XmppConnectionState.connecting:
        connection = ConnectionStatus.connecting;
        connectionHint =
            '\u041f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u0435...';
        break;
      case XmppConnectionState.connected:
        connection = ConnectionStatus.connected;
        connectionHint =
            '\u041f\u043e\u0434\u043a\u043b\u044e\u0447\u0435\u043d\u043e';
        break;
      case XmppConnectionState.error:
        connection = ConnectionStatus.error;
        connectionHint = xmpp.lastError.isEmpty
            ? '\u041e\u0448\u0438\u0431\u043a\u0430'
            : xmpp.lastError;
        break;
    }
    notifyListeners();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import 'package:app_design/features/contacts/domain/contact.dart';
import 'package:app_design/features/xmpp/domain/xmpp_bookmark.dart';
import 'package:app_design/features/xmpp/domain/xmpp_chat_message.dart';
import 'package:app_design/features/xmpp/domain/xmpp_room_presence.dart';

/// Minimal XMPP client: TCP, STARTTLS, SASL PLAIN, bind, presence, roster.
/// Adds basic MAM archive loading and live incoming message parsing.
///
/// This is intentionally small and keeps protocol details inside the XMPP layer.
/// UI state is exposed through notifiers and streams.
enum XmppConnectionState { disconnected, connecting, connected, error }

class XmppConfig {
  final String host;
  final String domain;
  final String username;
  final String password;

  const XmppConfig({
    required this.host,
    required this.domain,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'host': host,
        'domain': domain,
        'username': username,
        'password': password,
      };

  factory XmppConfig.fromJson(Map<String, dynamic> json) {
    return XmppConfig(
      host: (json['host'] ?? '').toString(),
      domain: (json['domain'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
    );
  }
}

class XmppService {
  static const _prefsKey = 'xmpp_config_v1';
  static const _prefsBadCertKey = 'xmpp_bad_certs_dev_v1';

  XmppService._();
  static final XmppService instance = XmppService._();

  // Public state for UI
  final ValueNotifier<List<Contact>> roster =
      ValueNotifier<List<Contact>>(<Contact>[]);
  final ValueNotifier<XmppConnectionState> connectionState =
      ValueNotifier<XmppConnectionState>(XmppConnectionState.disconnected);
  final StreamController<XmppChatMessage> _incomingMessages =
      StreamController<XmppChatMessage>.broadcast();
  Stream<XmppChatMessage> get incomingMessages => _incomingMessages.stream;
  final StreamController<XmppRoomPresence> _roomPresences =
      StreamController<XmppRoomPresence>.broadcast();
  Stream<XmppRoomPresence> get roomPresences => _roomPresences.stream;

  String lastError = '';

  // Config exposed for SettingsScreen (host/domain/user/pass)
  String host = '';
  String domain = '';
  String username = '';
  String password = '';

  // Auto-saved because SettingsScreen writes this flag after saving config.
  // Keep it as a property to preserve the existing settings flow.
  bool _allowBadCertificatesInDev = true;
  bool get allowBadCertificatesInDev => _allowBadCertificatesInDev;
  set allowBadCertificatesInDev(bool v) {
    _allowBadCertificatesInDev = v;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_prefsBadCertKey, v))
        .catchError((_) => false);
  }

  // ---- internals
  Socket? _socket;
  StreamSubscription<List<int>>? _sub;
  final StreamController<String> _stanzaStream =
      StreamController<String>.broadcast();
  String _buffer = '';

  String? _boundJid;
  String? get boundJid => _boundJid;
  final Map<String, String> _joinedRoomNicks = {};
  int _id = 0;
  int _nextId() => ++_id;

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _allowBadCertificatesInDev = prefs.getBool(_prefsBadCertKey) ?? true;

    final s = prefs.getString(_prefsKey);
    if (s == null) return;

    try {
      final json = jsonDecode(s) as Map<String, dynamic>;
      final cfg = XmppConfig.fromJson(json);
      host = _normalizeHost(cfg.host);
      domain = _normalizeHost(cfg.domain);
      username = cfg.username;
      password = cfg.password;
    } catch (_) {
      // ignore
    }
  }

  Future<void> saveConfig({
    required String host,
    required String domain,
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    final domainFromJid = _domainFromJid(normalizedUsername);
    this.host = _normalizeHost(
      host.trim().isEmpty ? (domainFromJid ?? domain) : host,
    );
    this.domain = _normalizeHost(
      domain.trim().isEmpty ? (domainFromJid ?? this.host) : domain,
    );
    this.username = normalizedUsername;
    this.password = password;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(
        XmppConfig(
          host: this.host,
          domain: this.domain,
          username: this.username,
          password: this.password,
        ).toJson(),
      ),
    );
    // badCerts is saved through allowBadCertificatesInDev setter.
  }

  Future<void> connectAndLoadRoster() async {
    lastError = '';
    if (connectionState.value == XmppConnectionState.connecting) return;
    connectionState.value = XmppConnectionState.connecting;

    if (kIsWeb) {
      _fail(
        '\u0412 \u0431\u0440\u0430\u0443\u0437\u0435\u0440\u0435 XMPP \u0447\u0435\u0440\u0435\u0437 TCP/5222 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d. \u0417\u0430\u043f\u0443\u0441\u0442\u0438 \u0434\u0435\u0441\u043a\u0442\u043e\u043f-\u0432\u0435\u0440\u0441\u0438\u044e \u0438\u043b\u0438 \u043d\u0443\u0436\u0435\u043d XMPP WebSocket/BOSH.',
      );
      return;
    }

    // Avoid hanging in connecting state when the config is incomplete.
    if (host.trim().isEmpty ||
        domain.trim().isEmpty ||
        username.trim().isEmpty ||
        password.isEmpty) {
      _fail(
          '\u0417\u0430\u043f\u043e\u043b\u043d\u0438 \u0445\u043e\u0441\u0442/\u0434\u043e\u043c\u0435\u043d/\u043b\u043e\u0433\u0438\u043d/\u043f\u0430\u0440\u043e\u043b\u044c');
      return;
    }

    try {
      await _closeTransport(setDisconnected: false, clearRoster: false);

      // 1) TCP connect (5222)
      _socket = await Socket.connect(host.trim(), 5222)
          .timeout(const Duration(seconds: 8));
      _listenSocket(_socket!);

      // 2) stream open + features
      await _openStream(domain.trim());
      final features1 =
          await _waitForStanza((s) => s.startsWith('<stream:features'))
              .timeout(const Duration(seconds: 8));

      // 3) STARTTLS if server offers it.
      if (_featuresHasStartTls(features1)) {
        await _sendRaw("<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>");
        await _waitForStanza((s) => s.startsWith('<proceed'))
            .timeout(const Duration(seconds: 8));

        final raw = _socket;
        if (raw == null) throw StateError('Socket is null while upgrading TLS');

        final secure = await SecureSocket.secure(
          raw,
          host: host.trim(),
          onBadCertificate: allowBadCertificatesInDev ? (_) => true : null,
        ).timeout(const Duration(seconds: 8));

        _socket = secure;
        await _relistenSocket(secure);

        // re-open stream and get features again
        await _openStream(domain.trim());
        await _waitForStanza((s) => s.startsWith('<stream:features'))
            .timeout(const Duration(seconds: 8));
      }

      // 4) SASL PLAIN
      await _saslPlain(_authUsername, password);

      // 5) reopen stream after SASL success.
      await _openStream(domain.trim());
      await _waitForStanza((s) => s.startsWith('<stream:features'))
          .timeout(const Duration(seconds: 8));

      // 6) bind
      await _bindResource('flutter-${DateTime.now().millisecondsSinceEpoch}');

      // 7) session, best effort.
      await _trySession();

      // 8) presence
      await _sendRaw('<presence/>');

      // 9) roster
      final rosterItems = await _fetchRoster();
      roster.value = rosterItems;

      connectionState.value = XmppConnectionState.connected;
    } catch (e) {
      await _closeTransport(setDisconnected: false, clearRoster: false);
      _fail(_prettyError(e));
    }
  }

  Future<void> disconnect({bool clearRoster = false}) async {
    await _closeTransport(setDisconnected: true, clearRoster: clearRoster);
  }

  Future<void> _closeTransport({
    required bool setDisconnected,
    required bool clearRoster,
  }) async {
    try {
      if (setDisconnected) {
        connectionState.value = XmppConnectionState.disconnected;
        lastError = '';
      }
      _boundJid = null;
      _joinedRoomNicks.clear();

      if (clearRoster) roster.value = <Contact>[];

      await _sub?.cancel();
      _sub = null;

      try {
        _socket?.destroy();
      } catch (_) {}
      _socket = null;

      _buffer = '';
    } catch (_) {
      // ignore
    }
  }

  Future<void> sendMessage(String toJid, String body) async {
    final to = toJid.trim();
    if (to.isEmpty) return;

    final s = _socket;
    if (s == null) {
      throw StateError(
          '\u041d\u0435\u0442 \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u044f XMPP');
    }

    final escaped = _xmlEscape(body);
    final stanza =
        "<message to='$to' type='chat'><body>$escaped</body></message>";

    s.add(utf8.encode(stanza));
    await s.flush();
  }

  Future<void> joinRoom(String roomJid, {String? nick}) async {
    final room = _bareJid(roomJid);
    if (room.isEmpty || _socket == null) return;

    final preferredNick = (nick ?? '').trim();
    final roomNick = preferredNick.isNotEmpty ? preferredNick : _authUsername;
    _joinedRoomNicks[room] = roomNick;
    await _sendRaw(
      "<presence to='${_xmlEscape(room)}/${_xmlEscape(roomNick)}'>"
      "<x xmlns='http://jabber.org/protocol/muc'/>"
      '</presence>',
    );
  }

  Future<void> sendGroupMessage(String roomJid, String body) async {
    final room = _bareJid(roomJid);
    if (room.isEmpty || _socket == null) return;

    await _sendRaw(
      "<message to='${_xmlEscape(room)}' type='groupchat'>"
      '<body>${_xmlEscape(body)}</body>'
      '</message>',
    );
  }

  Future<List<XmppChatMessage>> fetchChatArchive(
    String peerJid, {
    int max = 120,
  }) async {
    final to = _bareJid(peerJid);
    if (to.isEmpty || _socket == null) return const [];

    final v2 = await _fetchMamArchive(
      namespace: 'urn:xmpp:mam:2',
      peerJid: to,
      max: max,
    );
    if (v2.isNotEmpty) return v2;

    final v1 = await _fetchMamArchive(
      namespace: 'urn:xmpp:mam:1',
      peerJid: to,
      max: max,
    );
    if (v1.isNotEmpty) return v1;

    return _fetchRecentArchiveForPeer(to, max: max);
  }

  Future<List<XmppChatMessage>> fetchRoomArchive(
    String roomJid, {
    int max = 80,
  }) async {
    final room = _bareJid(roomJid);
    if (room.isEmpty || _socket == null) return const [];

    final v2 = await _fetchMamArchive(
      namespace: 'urn:xmpp:mam:2',
      peerJid: null,
      queryTo: room,
      max: max,
    );
    if (v2.isNotEmpty) return v2;

    return _fetchMamArchive(
      namespace: 'urn:xmpp:mam:1',
      peerJid: null,
      queryTo: room,
      max: max,
    );
  }

  Future<List<XmppChatMessage>> fetchRecentArchive({int max = 120}) async {
    if (_socket == null) return const [];

    final v2 = await _fetchMamArchive(
      namespace: 'urn:xmpp:mam:2',
      peerJid: null,
      max: max,
    );
    if (v2.isNotEmpty) return v2;

    return _fetchMamArchive(
      namespace: 'urn:xmpp:mam:1',
      peerJid: null,
      max: max,
    );
  }

  Future<List<XmppChatMessage>> _fetchRecentArchiveForPeer(
    String peerJid, {
    required int max,
  }) async {
    final peer = _bareJid(peerJid);
    if (peer.isEmpty || _socket == null) return const [];

    final recent = await fetchRecentArchive(max: max * 2);
    return recent.where((message) => message.peerJid == peer).toList();
  }

  Future<List<XmppBookmark>> fetchBookmarks() async {
    if (_socket == null) return const [];
    final legacy = await _fetchLegacyBookmarks();
    final modern = await _fetchPubSubBookmarks();
    final byJid = <String, XmppBookmark>{};
    for (final bookmark in [...legacy, ...modern]) {
      if (bookmark.jid.isEmpty) continue;
      byJid[bookmark.jid] = bookmark;
    }
    return byJid.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  // ----------------- low level -----------------

  void _listenSocket(Socket s) {
    _sub = s.listen(
      (data) {
        final chunk = utf8.decode(data, allowMalformed: true);
        _buffer += chunk;
        _drainBuffer();
      },
      onError: (e) {
        _fail('\u0421\u043e\u043a\u0435\u0442: $e');
      },
      onDone: () {
        if (connectionState.value != XmppConnectionState.disconnected) {
          _fail(
              '\u0421\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u0435 \u0437\u0430\u043a\u0440\u044b\u0442\u043e \u0441\u0435\u0440\u0432\u0435\u0440\u043e\u043c');
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _relistenSocket(Socket s) async {
    await _sub?.cancel();
    _sub = null;
    _listenSocket(s);
  }

  void _drainBuffer() {
    while (true) {
      final lt = _buffer.indexOf('<');
      if (lt == -1) return;
      if (lt > 0) _buffer = _buffer.substring(lt);

      // stream open
      if (_buffer.startsWith('<?xml')) {
        final idx = _buffer.indexOf('?>');
        if (idx == -1) return;
        _buffer = _buffer.substring(idx + 2);
        continue;
      }
      if (_buffer.startsWith('<stream:stream')) {
        final idx = _buffer.indexOf('>');
        if (idx == -1) return;
        _buffer = _buffer.substring(idx + 1);
        continue;
      }
      if (_buffer.startsWith('</stream:stream')) {
        final idx = _buffer.indexOf('>');
        if (idx == -1) return;
        _buffer = _buffer.substring(idx + 1);
        continue;
      }

      // features
      if (_buffer.startsWith('<stream:features')) {
        final end = _buffer.indexOf('</stream:features>');
        if (end == -1) return;
        final stanza = _buffer.substring(0, end + '</stream:features>'.length);
        _buffer = _buffer.substring(end + '</stream:features>'.length);
        _stanzaStream.add(stanza);
        continue;
      }

      final tag = _readTagName(_buffer);
      if (tag == null) {
        _buffer = _buffer.substring(1);
        continue;
      }

      final endIdx = _findStanzaEnd(_buffer, tag);
      if (endIdx == null) return;

      final stanza = _buffer.substring(0, endIdx);
      _buffer = _buffer.substring(endIdx);
      _stanzaStream.add(stanza);
      if (tag == 'message') {
        final liveMessage = _parseLiveMessage(stanza);
        if (liveMessage != null) _incomingMessages.add(liveMessage);
      } else if (tag == 'presence') {
        final roomPresence = _parseRoomPresence(stanza);
        if (roomPresence != null) _roomPresences.add(roomPresence);
      }
    }
  }

  String? _readTagName(String s) {
    final m = RegExp(r'^<([a-zA-Z0-9:_-]+)').firstMatch(s);
    return m?.group(1);
  }

  int? _findStanzaEnd(String s, String tag) {
    final gt = s.indexOf('>');
    if (gt == -1) return null;

    // self-closing: <tag .../>
    if (gt > 0 && s[gt - 1] == '/') {
      return gt + 1;
    }

    var depth = 0;
    var cursor = 0;
    while (cursor < s.length) {
      final lt = s.indexOf('<', cursor);
      if (lt == -1) return null;

      if (s.startsWith('<!--', lt)) {
        final end = s.indexOf('-->', lt + 4);
        if (end == -1) return null;
        cursor = end + 3;
        continue;
      }

      if (s.startsWith('<![CDATA[', lt)) {
        final end = s.indexOf(']]>', lt + 9);
        if (end == -1) return null;
        cursor = end + 3;
        continue;
      }

      final close = s.indexOf('>', lt + 1);
      if (close == -1) return null;

      final rawTag = s.substring(lt + 1, close).trim();
      if (rawTag.isEmpty || rawTag.startsWith('?') || rawTag.startsWith('!')) {
        cursor = close + 1;
        continue;
      }

      final isClosing = rawTag.startsWith('/');
      final isSelfClosing = rawTag.endsWith('/');
      final tagText = isClosing ? rawTag.substring(1).trim() : rawTag;
      final name = tagText.split(RegExp(r'\s+')).first.replaceAll('/', '');

      if (name == tag) {
        if (isClosing) {
          depth--;
          if (depth == 0) return close + 1;
        } else if (!isSelfClosing) {
          depth++;
        } else if (depth == 0) {
          return close + 1;
        }
      }

      cursor = close + 1;
    }
    return null;
  }

  Future<void> _sendRaw(String xml) async {
    final s = _socket;
    if (s == null) throw StateError('Socket is null');
    s.add(utf8.encode(xml));
    await s.flush();
  }

  bool _hasAttr(String stanza, String attr, String value) {
    return stanza.contains("$attr='$value'") ||
        stanza.contains('$attr="$value"');
  }

  Future<String> _waitForStanza(bool Function(String) pred) async {
    await for (final s in _stanzaStream.stream) {
      if (pred(s)) return s;
    }
    throw StateError('Stanza stream closed');
  }

  Future<void> _openStream(String toDomain) async {
    final xml =
        "<?xml version='1.0'?><stream:stream to='$toDomain' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' version='1.0'>";
    await _sendRaw(xml);
  }

  bool _featuresHasStartTls(String featuresXml) {
    try {
      final doc = XmlDocument.parse(featuresXml);
      return doc.descendants.whereType<XmlElement>().any((e) =>
          e.name.local == 'starttls' &&
          (e.getAttribute('xmlns') == 'urn:ietf:params:xml:ns:xmpp-tls' ||
              e.attributes.any((a) =>
                  a.name.local == 'xmlns' &&
                  a.value == 'urn:ietf:params:xml:ns:xmpp-tls')));
    } catch (_) {
      return featuresXml.contains('xmpp-tls');
    }
  }

  Future<void> _saslPlain(String user, String pass) async {
    final payload = base64Encode(utf8.encode('\u0000$user\u0000$pass'));
    final auth =
        "<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>$payload</auth>";
    await _sendRaw(auth);

    final res = await _waitForStanza(
      (s) => s.startsWith('<success') || s.startsWith('<failure'),
    ).timeout(const Duration(seconds: 8));

    if (res.startsWith('<failure')) {
      throw StateError(
          'SASL: \u043d\u0435\u0432\u0435\u0440\u043d\u044b\u0439 \u043b\u043e\u0433\u0438\u043d/\u043f\u0430\u0440\u043e\u043b\u044c');
    }
  }

  Future<List<XmppChatMessage>> _fetchMamArchive({
    required String namespace,
    required String? peerJid,
    String? queryTo,
    required int max,
  }) async {
    final id = 'mam_${_nextId()}';
    final queryId = 'q_$id';
    final toAttr = queryTo == null || queryTo.trim().isEmpty
        ? ''
        : " to='${_xmlEscape(queryTo)}'";
    final withField = peerJid == null || peerJid.trim().isEmpty
        ? ''
        : "<field var='with'><value>${_xmlEscape(peerJid)}</value></field>";
    final iq = [
      "<iq type='set' id='$id'$toAttr>",
      "<query xmlns='$namespace' queryid='$queryId'>",
      "<x xmlns='jabber:x:data' type='submit'>",
      "<field var='FORM_TYPE' type='hidden'><value>$namespace</value></field>",
      withField,
      '</x>',
      "<set xmlns='http://jabber.org/protocol/rsm'><max>$max</max></set>",
      '</query>',
      '</iq>',
    ].join();

    await _sendRaw(iq);
    final messages = <XmppChatMessage>[];

    try {
      await for (final stanza in _stanzaStream.stream.timeout(
        const Duration(seconds: 10),
        onTimeout: (sink) => sink.close(),
      )) {
        if (stanza.startsWith('<message') && stanza.contains(queryId)) {
          final archived = _parseMamMessage(stanza, peerJid ?? '');
          if (archived != null) messages.add(archived);
          continue;
        }

        if (stanza.startsWith('<iq') && _hasAttr(stanza, 'id', id)) {
          if (_hasAttr(stanza, 'type', 'error')) return const [];
          break;
        }
      }
    } catch (_) {
      return const [];
    }

    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<List<XmppBookmark>> _fetchLegacyBookmarks() async {
    final id = 'bookmarks_legacy_${_nextId()}';
    final iq = [
      "<iq type='get' id='$id'>",
      "<query xmlns='jabber:iq:private'>",
      "<storage xmlns='storage:bookmarks'/>",
      '</query>',
      '</iq>',
    ].join();
    await _sendRaw(iq);

    try {
      final res = await _waitForStanza(
        (s) => s.startsWith('<iq') && _hasAttr(s, 'id', id),
      ).timeout(const Duration(seconds: 8));
      if (_hasAttr(res, 'type', 'error')) return const [];
      final doc = XmlDocument.parse(res);
      return doc.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'conference')
          .map(_bookmarkFromConference)
          .whereType<XmppBookmark>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<XmppBookmark>> _fetchPubSubBookmarks() async {
    final id = 'bookmarks_pubsub_${_nextId()}';
    final iq = [
      "<iq type='get' id='$id'>",
      "<pubsub xmlns='http://jabber.org/protocol/pubsub'>",
      "<items node='urn:xmpp:bookmarks:1'/>",
      '</pubsub>',
      '</iq>',
    ].join();
    await _sendRaw(iq);

    try {
      final res = await _waitForStanza(
        (s) => s.startsWith('<iq') && _hasAttr(s, 'id', id),
      ).timeout(const Duration(seconds: 8));
      if (_hasAttr(res, 'type', 'error')) return const [];
      final doc = XmlDocument.parse(res);
      return doc.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'conference')
          .map(_bookmarkFromConference)
          .whereType<XmppBookmark>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  XmppBookmark? _bookmarkFromConference(XmlElement element) {
    final jid = (element.getAttribute('jid') ?? '').trim();
    if (jid.isEmpty) return null;
    final name = (element.getAttribute('name') ?? '').trim();
    final nick = element.children.whereType<XmlElement>().where(
          (child) => child.name.local == 'nick',
        );
    return XmppBookmark(
      jid: _bareJid(jid),
      name: name.isEmpty ? _jidUserPart(jid) : name,
      nick: nick.isEmpty ? null : nick.first.innerText.trim(),
    );
  }

  XmppChatMessage? _parseMamMessage(String stanza, String requestedPeerJid) {
    try {
      final doc = XmlDocument.parse(stanza);
      final result = doc.descendants.whereType<XmlElement>().firstWhere(
            (element) => element.name.local == 'result',
          );
      final archiveId = result.getAttribute('id') ?? 'mam-${_nextId()}';
      final forwarded = result.descendants.whereType<XmlElement>().firstWhere(
            (element) => element.name.local == 'forwarded',
          );
      final forwardedMessage =
          forwarded.children.whereType<XmlElement>().firstWhere(
                (element) => element.name.local == 'message',
              );
      final body = forwardedMessage.children.whereType<XmlElement>().firstWhere(
            (element) => element.name.local == 'body',
          );
      final delay = forwarded.descendants.whereType<XmlElement>().where(
            (element) => element.name.local == 'delay',
          );

      final from = _bareJid(forwardedMessage.getAttribute('from') ?? '');
      final to = _bareJid(forwardedMessage.getAttribute('to') ?? '');
      final type = forwardedMessage.getAttribute('type') ?? '';
      final groupChat = type == 'groupchat' || _isKnownRoomJid(from);
      final mine = _myBareJid;
      final fromFull = forwardedMessage.getAttribute('from') ?? '';
      final roomNick = _joinedRoomNicks[from] ?? '';
      final outgoing =
          groupChat ? _resourceFromJid(fromFull) == roomNick : from == mine;
      final peer = groupChat ? from : (outgoing ? to : from);
      final stamp = delay.isEmpty ? null : delay.first.getAttribute('stamp');

      return XmppChatMessage(
        id: archiveId,
        peerJid: peer.isEmpty ? _bareJid(requestedPeerJid) : peer,
        fromJid: groupChat ? _resourceFromJid(fromFull) : from,
        toJid: to,
        body: body.innerText,
        timestamp: _parseXmppDate(stamp) ?? DateTime.now(),
        outgoing: outgoing,
        archived: true,
        groupChat: groupChat,
      );
    } catch (_) {
      return null;
    }
  }

  XmppChatMessage? _parseLiveMessage(String stanza) {
    if (stanza.contains('urn:xmpp:mam:')) return null;
    try {
      final doc = XmlDocument.parse(stanza);
      final message = doc.rootElement;
      if (message.name.local != 'message') return null;
      final type = message.getAttribute('type') ?? '';
      final bodies = message.children.whereType<XmlElement>().where(
            (element) => element.name.local == 'body',
          );
      if (bodies.isEmpty) return null;

      final fromFull = message.getAttribute('from') ?? '';
      final from = _bareJid(fromFull);
      final to = _bareJid(message.getAttribute('to') ?? '');
      final body = bodies.first.innerText.trim();
      if (body.isEmpty || from.isEmpty) return null;

      final groupChat = type == 'groupchat' || _isKnownRoomJid(from);
      final roomNick = _joinedRoomNicks[from] ?? '';
      final mine = _myBareJid;
      final outgoing =
          groupChat ? _resourceFromJid(fromFull) == roomNick : from == mine;
      return XmppChatMessage(
        id: message.getAttribute('id') ??
            'live-${DateTime.now().microsecondsSinceEpoch}',
        peerJid: groupChat ? from : (outgoing ? to : from),
        fromJid: groupChat ? _resourceFromJid(fromFull) : from,
        toJid: to,
        body: body,
        timestamp: DateTime.now(),
        outgoing: outgoing,
        archived: false,
        groupChat: groupChat,
      );
    } catch (_) {
      return null;
    }
  }

  XmppRoomPresence? _parseRoomPresence(String stanza) {
    try {
      final doc = XmlDocument.parse(stanza);
      final presence = doc.rootElement;
      if (presence.name.local != 'presence') return null;

      final fromFull = presence.getAttribute('from') ?? '';
      final room = _bareJid(fromFull);
      final nick = _resourceFromJid(fromFull);
      if (room.isEmpty || nick.isEmpty) return null;
      if (!_isKnownRoomJid(room)) return null;

      final item = presence.descendants.whereType<XmlElement>().where(
            (element) => element.name.local == 'item',
          );
      final realJid =
          item.isEmpty ? '' : (item.first.getAttribute('jid') ?? '');
      final participantId =
          _bareJid(realJid).isEmpty ? nick : _bareJid(realJid);

      return XmppRoomPresence(
        roomJid: room,
        participantId: participantId,
        nick: nick,
        available: presence.getAttribute('type') != 'unavailable',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _bindResource(String resource) async {
    final id = 'bind_${_nextId()}';
    final iq =
        "<iq type='set' id='$id'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'><resource>$resource</resource></bind></iq>";
    await _sendRaw(iq);

    final res = await _waitForStanza(
      (s) =>
          s.startsWith('<iq') &&
          _hasAttr(s, 'id', id) &&
          _hasAttr(s, 'type', 'result'),
    ).timeout(const Duration(seconds: 8));

    try {
      final doc = XmlDocument.parse(res);
      final jidEl = doc.descendants
          .whereType<XmlElement>()
          .firstWhere((e) => e.name.local == 'jid');
      _boundJid = jidEl.innerText;
    } catch (_) {
      // Non-critical: bound JID is used only for message direction.
    }
  }

  Future<void> _trySession() async {
    final id = 'sess_${_nextId()}';
    final iq =
        "<iq type='set' id='$id'><session xmlns='urn:ietf:params:xml:ns:xmpp-session'/></iq>";
    await _sendRaw(iq);

    try {
      await _waitForStanza(
        (s) => s.startsWith('<iq') && _hasAttr(s, 'id', id),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<List<Contact>> _fetchRoster() async {
    final id = 'roster_${_nextId()}';
    final iq = "<iq type='get' id='$id'><query xmlns='jabber:iq:roster'/></iq>";
    await _sendRaw(iq);

    final res = await _waitForStanza(
      (s) =>
          s.startsWith('<iq') &&
          _hasAttr(s, 'id', id) &&
          _hasAttr(s, 'type', 'result'),
    ).timeout(const Duration(seconds: 8));

    final list = <Contact>[];

    try {
      final doc = XmlDocument.parse(res);
      final items = doc.descendants.whereType<XmlElement>().where(
            (e) => e.name.local == 'item' && e.getAttribute('jid') != null,
          );

      for (final it in items) {
        final jid = (it.getAttribute('jid') ?? '').trim();
        if (jid.isEmpty) continue;

        final nameAttr = (it.getAttribute('name') ?? '').trim();
        final display = nameAttr.isNotEmpty ? nameAttr : _jidUserPart(jid);

        list.add(
          Contact(
            jid: jid,
            displayName: display,
            lastMessage: null,
            time: null,
            status: 'Offline',
          ),
        );
      }
    } catch (_) {
      // If roster parsing fails, return an empty list and keep the app alive.
    }

    list.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list;
  }

  String _jidUserPart(String jid) {
    final at = jid.indexOf('@');
    if (at == -1) return jid;
    return jid.substring(0, at);
  }

  String _normalizeHost(String value) {
    var text = value.trim();
    if (text.startsWith('https://')) text = text.substring(8);
    if (text.startsWith('http://')) text = text.substring(7);
    final slash = text.indexOf('/');
    if (slash != -1) text = text.substring(0, slash);
    final colon = text.indexOf(':');
    if (colon != -1) text = text.substring(0, colon);
    return text.trim();
  }

  String? _domainFromJid(String value) {
    final at = value.indexOf('@');
    if (at == -1 || at == value.length - 1) return null;
    return _normalizeHost(value.substring(at + 1));
  }

  String get _authUsername {
    final value = username.trim();
    final at = value.indexOf('@');
    return at == -1 ? value : value.substring(0, at);
  }

  String get _myBareJid {
    final bound = _boundJid;
    if (bound != null && bound.trim().isNotEmpty) return _bareJid(bound);
    final value = username.trim();
    if (value.contains('@')) return _bareJid(value);
    if (domain.trim().isEmpty) return value;
    return '$value@${domain.trim()}';
  }

  String _bareJid(String jid) {
    final slash = jid.indexOf('/');
    return (slash == -1 ? jid : jid.substring(0, slash)).trim();
  }

  String _resourceFromJid(String jid) {
    final slash = jid.indexOf('/');
    if (slash == -1 || slash == jid.length - 1) return '';
    return jid.substring(slash + 1).trim();
  }

  bool _isKnownRoomJid(String jid) {
    final bare = _bareJid(jid);
    return _joinedRoomNicks.containsKey(bare) ||
        bare.contains('@conference.') ||
        bare.contains('@muc.');
  }

  DateTime? _parseXmppDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  void _fail(String msg) {
    lastError = msg;
    connectionState.value = XmppConnectionState.error;
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('TimeoutException')) {
      return '\u0422\u0430\u0439\u043c\u0430\u0443\u0442 \u0441\u043e\u0435\u0434\u0438\u043d\u0435\u043d\u0438\u044f';
    }
    return s;
  }

  String _xmlEscape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

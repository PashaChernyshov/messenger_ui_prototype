import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import '../../contacts/data/contact.dart';
import '../data/xmpp_config.dart';

/// Упрощённый XMPP-клиент под Openfire (локалка).
enum XmppConnectionState { disconnected, connecting, connected, error }

class XmppService {
  static const _prefsKey = 'xmpp_config_v1';
  static const _prefsBadCertKey = 'xmpp_bad_certs_dev_v1';

  XmppService._();
  static final XmppService instance = XmppService._();

  final ValueNotifier<List<Contact>> roster =
      ValueNotifier<List<Contact>>(<Contact>[]);
  final ValueNotifier<XmppConnectionState> connectionState =
      ValueNotifier<XmppConnectionState>(XmppConnectionState.disconnected);

  String lastError = '';

  String host = '';
  String domain = '';
  String username = '';
  String password = '';

  bool _allowBadCertificatesInDev = true;
  bool get allowBadCertificatesInDev => _allowBadCertificatesInDev;
  set allowBadCertificatesInDev(bool v) {
    _allowBadCertificatesInDev = v;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_prefsBadCertKey, v))
        .catchError((_) {});
  }

  Socket? _socket;
  StreamSubscription<List<int>>? _sub;
  final StreamController<String> _stanzaStream =
      StreamController<String>.broadcast();
  String _buffer = '';

  String? _boundJid;
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
      host = cfg.host;
      domain = cfg.domain;
      username = cfg.username;
      password = cfg.password;
    } catch (_) {}
  }

  Future<void> saveConfig({
    required String host,
    required String domain,
    required String username,
    required String password,
  }) async {
    this.host = host.trim();
    this.domain = domain.trim();
    this.username = username.trim();
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
  }

  Future<void> connectAndLoadRoster() async {
    lastError = '';
    if (connectionState.value == XmppConnectionState.connecting) return;
    connectionState.value = XmppConnectionState.connecting;

    if (host.trim().isEmpty ||
        domain.trim().isEmpty ||
        username.trim().isEmpty ||
        password.isEmpty) {
      _fail('Заполни хост/домен/логин/пароль');
      return;
    }

    try {
      await disconnect(clearRoster: false);

      _socket = await Socket.connect(host.trim(), 5222)
          .timeout(const Duration(seconds: 8));
      _listenSocket(_socket!);

      await _openStream(domain.trim());
      final features1 =
          await _waitForStanza((s) => s.startsWith('<stream:features'))
              .timeout(const Duration(seconds: 8));

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

        await _openStream(domain.trim());
        await _waitForStanza((s) => s.startsWith('<stream:features'))
            .timeout(const Duration(seconds: 8));
      }

      await _saslPlain(username.trim(), password);

      await _openStream(domain.trim());
      await _waitForStanza((s) => s.startsWith('<stream:features'))
          .timeout(const Duration(seconds: 8));

      await _bindResource('flutter-${DateTime.now().millisecondsSinceEpoch}');
      await _trySession();

      await _sendRaw('<presence/>');

      final rosterItems = await _fetchRoster();
      roster.value = rosterItems;

      connectionState.value = XmppConnectionState.connected;
    } catch (e) {
      _fail(_prettyError(e));
      await disconnect(clearRoster: false);
    }
  }

  Future<void> disconnect({bool clearRoster = false}) async {
    try {
      connectionState.value = XmppConnectionState.disconnected;
      lastError = '';
      _boundJid = null;

      if (clearRoster) roster.value = <Contact>[];

      await _sub?.cancel();
      _sub = null;

      try {
        _socket?.destroy();
      } catch (_) {}
      _socket = null;

      _buffer = '';
    } catch (_) {}
  }

  Future<void> sendMessage(String toJid, String body) async {
    final to = toJid.trim();
    if (to.isEmpty) return;

    final s = _socket;
    if (s == null) {
      throw StateError('Нет соединения XMPP');
    }

    final escaped = _xmlEscape(body);
    final stanza =
        "<message to='$to' type='chat'><body>$escaped</body></message>";

    s.add(utf8.encode(stanza));
    await s.flush();
  }

  void _listenSocket(Socket s) {
    _sub = s.listen(
      (data) {
        final chunk = utf8.decode(data, allowMalformed: true);
        _buffer += chunk;
        _drainBuffer();
      },
      onError: (e) {
        _fail('Сокет: $e');
      },
      onDone: () {
        if (connectionState.value != XmppConnectionState.disconnected) {
          _fail('Соединение закрыто сервером');
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
    }
  }

  String? _readTagName(String s) {
    final m = RegExp(r'^<([a-zA-Z0-9:_-]+)').firstMatch(s);
    return m?.group(1);
  }

  int? _findStanzaEnd(String s, String tag) {
    final gt = s.indexOf('>');
    if (gt == -1) return null;

    if (gt > 0 && s[gt - 1] == '/') {
      return gt + 1;
    }

    final endTag = '</$tag>';
    final end = s.indexOf(endTag);
    if (end == -1) return null;
    return end + endTag.length;
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
      throw StateError('SASL: неверный логин/пароль');
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
    } catch (_) {}
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
    } catch (_) {}

    list.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list;
  }

  String _jidUserPart(String jid) {
    final at = jid.indexOf('@');
    if (at == -1) return jid;
    return jid.substring(0, at);
  }

  void _fail(String msg) {
    lastError = msg;
    connectionState.value = XmppConnectionState.error;
  }

  String _prettyError(Object e) {
    final s = e.toString();
    if (s.contains('TimeoutException')) return 'Таймаут соединения';
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

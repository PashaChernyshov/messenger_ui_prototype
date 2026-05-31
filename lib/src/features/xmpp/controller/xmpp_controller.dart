import 'package:flutter/foundation.dart';

import '../../../core/storage/prefs_store.dart';
import '../service/xmpp_service.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class XmppController extends ChangeNotifier {
  final PrefsStore _prefs;
  final XmppService _xmpp;

  XmppController(this._prefs, this._xmpp);

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _hint = 'Отключено';

  ConnectionStatus get status => _status;
  String get hint => _hint;

  XmppService get service => _xmpp;

  void bootstrap() {
    _xmpp.connectionState.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    _xmpp.connectionState.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    switch (_xmpp.connectionState.value) {
      case XmppConnectionState.disconnected:
        _status = ConnectionStatus.disconnected;
        _hint = 'Отключено';
        break;
      case XmppConnectionState.connecting:
        _status = ConnectionStatus.connecting;
        _hint = 'Подключение…';
        break;
      case XmppConnectionState.connected:
        _status = ConnectionStatus.connected;
        _hint = 'Подключено';
        break;
      case XmppConnectionState.error:
        _status = ConnectionStatus.error;
        _hint = _xmpp.lastError.isEmpty ? 'Ошибка' : _xmpp.lastError;
        break;
    }
    notifyListeners();
  }

  Future<void> connect() async => _xmpp.connectAndLoadRoster();
  Future<void> disconnect() async => _xmpp.disconnect();

  // settings proxies
  String get host => _xmpp.host;
  String get domain => _xmpp.domain;
  String get username => _xmpp.username;
  String get password => _xmpp.password;

  bool get allowBadCertificatesInDev => _xmpp.allowBadCertificatesInDev;
  set allowBadCertificatesInDev(bool v) => _xmpp.allowBadCertificatesInDev = v;

  Future<void> saveConfig({
    required String host,
    required String domain,
    required String username,
    required String password,
  }) async {
    await _xmpp.saveConfig(
      host: host,
      domain: domain,
      username: username,
      password: password,
    );
  }
}

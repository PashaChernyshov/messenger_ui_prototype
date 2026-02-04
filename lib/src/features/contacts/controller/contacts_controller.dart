import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../xmpp/service/xmpp_service.dart';
import '../data/contact.dart';

class ContactsController extends ChangeNotifier {
  final XmppService _xmpp;

  ContactsController(this._xmpp);

  List<Contact> _contacts = const [];
  List<Contact> get contacts => _contacts;

  void bootstrap() {
    _contacts = List<Contact>.from(_xmpp.roster.value);
    _xmpp.roster.addListener(_onRosterChanged);
  }

  void disposeController() {
    _xmpp.roster.removeListener(_onRosterChanged);
  }

  void _onRosterChanged() {
    _contacts = List<Contact>.from(_xmpp.roster.value);
    notifyListeners();
  }

  Contact createStubContact({required String domain}) {
    final id = Random().nextInt(9999);
    final jid = 'user$id@${domain.isEmpty ? "example.com" : domain}';
    final c = Contact(
      jid: jid,
      displayName: 'Клиент #$id',
      lastMessage: 'Добрый день! Есть вопрос…',
      time: 'сейчас',
      status: 'Online',
    );

    _contacts = [c, ..._contacts];
    notifyListeners();
    return c;
  }
}

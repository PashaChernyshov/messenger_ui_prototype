import 'package:flutter/foundation.dart';

import '../data/call_entry.dart';

class CallsController extends ChangeNotifier {
  List<CallEntry> _calls = const [];
  List<CallEntry> get calls => _calls;

  void bootstrap() {
    final now = DateTime.now();
    _calls = [
      CallEntry(
        id: 'c1',
        peerName: 'Служба поддержки',
        peerId: 'support@example.com',
        isGroup: false,
        outgoing: true,
        missed: false,
        ts: now.subtract(const Duration(minutes: 25)),
      ),
      CallEntry(
        id: 'c2',
        peerName: 'Отдел продаж',
        peerId: 'group:sales',
        isGroup: true,
        outgoing: false,
        missed: true,
        ts: now.subtract(const Duration(hours: 2, minutes: 5)),
      ),
      CallEntry(
        id: 'c3',
        peerName: 'Клиент #2041',
        peerId: 'client2041@example.com',
        isGroup: false,
        outgoing: false,
        missed: false,
        ts: now.subtract(const Duration(days: 1, hours: 1)),
      ),
    ];
  }
}

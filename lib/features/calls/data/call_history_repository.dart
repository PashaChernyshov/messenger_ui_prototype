import 'package:app_design/features/calls/domain/call_entry.dart';

abstract interface class CallHistoryRepository {
  List<CallEntry> loadDemoCalls();
}

class DemoCallHistoryRepository implements CallHistoryRepository {
  @override
  List<CallEntry> loadDemoCalls() {
    final now = DateTime.now();
    return [
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

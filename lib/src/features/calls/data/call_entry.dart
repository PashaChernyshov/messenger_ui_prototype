class CallEntry {
  final String id;
  final String peerName;
  final String peerId; // jid or groupId
  final bool isGroup;
  final bool outgoing;
  final bool missed;
  final DateTime ts;

  const CallEntry({
    required this.id,
    required this.peerName,
    required this.peerId,
    required this.isGroup,
    required this.outgoing,
    required this.missed,
    required this.ts,
  });
}

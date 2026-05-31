class XmppChatMessage {
  final String id;
  final String peerJid;
  final String fromJid;
  final String toJid;
  final String body;
  final DateTime timestamp;
  final bool outgoing;
  final bool archived;
  final bool groupChat;

  const XmppChatMessage({
    required this.id,
    required this.peerJid,
    required this.fromJid,
    required this.toJid,
    required this.body,
    required this.timestamp,
    required this.outgoing,
    required this.archived,
    this.groupChat = false,
  });
}

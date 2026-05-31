class XmppRoomPresence {
  final String roomJid;
  final String participantId;
  final String nick;
  final bool available;

  const XmppRoomPresence({
    required this.roomJid,
    required this.participantId,
    required this.nick,
    required this.available,
  });
}

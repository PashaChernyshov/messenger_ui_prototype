class XmppBookmark {
  final String jid;
  final String name;
  final String? nick;

  const XmppBookmark({
    required this.jid,
    required this.name,
    this.nick,
  });
}

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

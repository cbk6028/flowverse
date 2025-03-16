class WebDavAccount {
  final String name;
  final String type;
  final String server;
  final String username;
  final String password;
  final String path;
  final int port;
  final bool allowSelfSigned;

  WebDavAccount({
    required this.name,
    required this.type,
    required this.server,
    required this.username,
    required this.password,
    required this.path,
    required this.port,
    required this.allowSelfSigned,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'server': server,
      'username': username,
      'password': password,
      'path': path,
      'port': port,
      'allowSelfSigned': allowSelfSigned,
    };
  }

  factory WebDavAccount.fromJson(Map<String, dynamic> json) {
    return WebDavAccount(
      name: json['name'],
      type: json['type'],
      server: json['server'],
      username: json['username'],
      password: json['password'],
      path: json['path'],
      port: json['port'],
      allowSelfSigned: json['allowSelfSigned'],
    );
  }
} 
import 'dart:convert';

/// Server - 伺服器模型 (如 WebDAV)
/// (原 Android data/entities/Server.kt)
class Server {
  int id;
  String name;
  String type; // 'WEBDAV'
  String? config;
  int sortNumber;

  Server({
    required this.id,
    this.name = '',
    this.type = 'WEBDAV',
    this.config,
    this.sortNumber = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'config': config,
      'sortNumber': sortNumber,
    };
  }

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'WEBDAV',
      config: json['config'],
      sortNumber: json['sortNumber'] ?? 0,
    );
  }

  WebDavConfig? get webDavConfig {
    if (type == 'WEBDAV' && config != null) {
      try {
        return WebDavConfig.fromJson(jsonDecode(config!));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class WebDavConfig {
  String url;
  String username;
  String password;

  WebDavConfig({
    required this.url,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'username': username,
    'password': password,
  };
  factory WebDavConfig.fromJson(Map<String, dynamic> json) => WebDavConfig(
    url: json['url'] ?? '',
    username: json['username'] ?? '',
    password: json['password'] ?? '',
  );
}


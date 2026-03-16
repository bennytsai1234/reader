import 'dart:convert';

/// RssArticle - RSS 文章模型
/// (原 Android data/entities/RssArticle.kt)
class RssArticle {
  String origin;
  String sort;
  String title;
  int order;
  String link;
  String? pubDate;
  String? description;
  String? content;
  String? image;
  String group;
  bool read;
  String? variable;

  Map<String, String> get variableMap {
    if (variable == null || variable!.isEmpty) return {};
    try {
      final map = jsonDecode(variable!) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  String? getVariable(String key) => variableMap[key];

  void putVariable(String key, String val) {
    final map = variableMap;
    map[key] = val;
    variable = jsonEncode(map);
  }

  RssArticle({
    required this.origin,
    this.sort = '',
    this.title = '',
    this.order = 0,
    required this.link,
    this.pubDate,
    this.description,
    this.content,
    this.image,
    this.group = '預設分組',
    this.read = false,
    this.variable,
  });

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'sort': sort,
      'title': title,
      'order': order,
      'link': link,
      'pubDate': pubDate,
      'description': description,
      'content': content,
      'image': image,
      'group': group,
      'read': read ? 1 : 0,
      'variable': variable,
    };
  }

  factory RssArticle.fromJson(Map<String, dynamic> json) {
    return RssArticle(
      origin: json['origin'] ?? '',
      sort: json['sort'] ?? '',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
      link: json['link'] ?? '',
      pubDate: json['pubDate'],
      description: json['description'],
      content: json['content'],
      image: json['image'],
      group: json['group'] ?? '預設分組',
      read: json['read'] == 1 || json['read'] == true,
      variable: json['variable'],
    );
  }
}


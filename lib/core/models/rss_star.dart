import 'dart:convert';
import 'base_rss_article.dart';

/// RssStar - RSS 收藏模型
/// (原 Android data/entities/RssStar.kt)
class RssStar extends BaseRssArticle {
  @override
  String origin;
  String sort;
  String title;
  int starTime;
  @override
  String link;
  String? pubDate;
  String? description;
  String? content;
  String? image;
  String group;
  @override
  String? variable;

  @override
  final Map<String, String> variableMap;

  RssStar({
    this.origin = '',
    this.sort = '',
    this.title = '',
    this.starTime = 0,
    this.link = '',
    this.pubDate,
    this.description,
    this.content,
    this.image,
    this.group = '默认分组',
    this.variable,
  }) : variableMap =
           variable != null
               ? Map<String, String>.from(jsonDecode(variable))
               : {};

  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'sort': sort,
      'title': title,
      'starTime': starTime,
      'link': link,
      'pubDate': pubDate,
      'description': description,
      'content': content,
      'image': image,
      'group': group,
      'variable': variable,
    };
  }

  factory RssStar.fromJson(Map<String, dynamic> json) {
    return RssStar(
      origin: json['origin'] ?? '',
      sort: json['sort'] ?? '',
      title: json['title'] ?? '',
      starTime: json['starTime'] ?? 0,
      link: json['link'] ?? '',
      pubDate: json['pubDate'],
      description: json['description'],
      content: json['content'],
      image: json['image'],
      group: json['group'] ?? '默认分组',
      variable: json['variable'],
    );
  }
}


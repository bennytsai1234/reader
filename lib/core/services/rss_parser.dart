import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/models/rss_article.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

/// RssParser - RSS 解析引擎
/// 支援標準 XML 與自訂規則解析
class RssParser {
  RssParser._();

  /// 解析文章列表
  static Future<List<RssArticle>> parseArticles(
    RssSource source,
    String body,
    String baseUrl,
  ) async {
    return await compute((_) {
      // 如果定義了 ruleArticles，使用規則解析
      if (source.ruleArticles != null && source.ruleArticles!.isNotEmpty) {
        return _parseByRule(source, body, baseUrl);
      }
      // 否則使用預設 XML 解析
      return _parseDefault(source, body, baseUrl);
    }, null);
  }

  /// 預設 XML 解析 (RSS/Atom)
  static List<RssArticle> _parseDefault(
    RssSource source,
    String body,
    String baseUrl,
  ) {
    try {
      final document = XmlDocument.parse(body);
      final articles = <RssArticle>[];

      // 嘗試 RSS 2.0 (item)
      final items = document.findAllElements('item');
      if (items.isNotEmpty) {
        for (final item in items) {
          articles.add(
            RssArticle(
              origin: source.sourceUrl,
              link: item.findElements('link').firstOrNull?.innerText ?? '',
              title: item.findElements('title').firstOrNull?.innerText ?? '無標題',
              pubDate: item.findElements('pubDate').firstOrNull?.innerText,
              description:
                  item.findElements('description').firstOrNull?.innerText,
            ),
          );
        }
        return articles;
      }

      // 嘗試 Atom (entry)
      final entries = document.findAllElements('entry');
      for (final entry in entries) {
        articles.add(
          RssArticle(
            origin: source.sourceUrl,
            link: entry.findElements('link').firstOrNull?.getAttribute('href') ??
                entry.findElements('link').firstOrNull?.innerText ??
                '',
            title: entry.findElements('title').firstOrNull?.innerText ?? '無標題',
            pubDate: entry.findElements('updated').firstOrNull?.innerText ??
                entry.findElements('published').firstOrNull?.innerText,
            description: entry.findElements('summary').firstOrNull?.innerText ??
                entry.findElements('content').firstOrNull?.innerText,
          ),
        );
      }
      return articles;
    } catch (e) {
      // 如果 XML 解析失敗，嘗試簡單的 HTML 鏈接提取作為後備
      return _parseHtmlFallback(source, body, baseUrl);
    }
  }

  /// 規則解析
  static List<RssArticle> _parseByRule(
    RssSource source,
    String body,
    String baseUrl,
  ) {
    final analyzer = AnalyzeRule(source: source);
    final rule = analyzer.setContent(body, baseUrl: baseUrl);
    final elements = rule.getElements(source.ruleArticles!);
    final articles = <RssArticle>[];

    for (final element in elements) {
      final itemRule = AnalyzeRule(source: source).setContent(element, baseUrl: baseUrl);
      articles.add(
        RssArticle(
          origin: source.sourceUrl,
          link: itemRule.getString(source.ruleLink ?? '', isUrl: true),
          title: itemRule.getString(source.ruleTitle ?? ''),
          pubDate: itemRule.getString(source.rulePubDate ?? ''),
          description: itemRule.getString(source.ruleDescription ?? ''),
          image: itemRule.getString(source.ruleImage ?? '', isUrl: true),
        ),
      );
    }
    return articles;
  }

  /// HTML 後備解析
  static List<RssArticle> _parseHtmlFallback(
    RssSource source,
    String body,
    String baseUrl,
  ) {
    final document = html_parser.parse(body);
    final links = document.querySelectorAll('a');
    final articles = <RssArticle>[];

    for (final link in links) {
      final href = link.attributes['href'];
      final title = link.text.trim();
      if (href != null && title.isNotEmpty) {
        articles.add(
          RssArticle(
            origin: source.sourceUrl,
            link: Uri.parse(baseUrl).resolve(href).toString(),
            title: title,
          ),
        );
      }
    }
    return articles;
  }

  /// 解析文章正文 (如果來源定義了 ruleContent)
  static Future<String> parseContent(
    RssSource source,
    String body,
    String baseUrl,
  ) async {
    if (source.ruleContent != null && source.ruleContent!.isNotEmpty) {
      final analyzer = AnalyzeRule(source: source);
      final rule = analyzer.setContent(body, baseUrl: baseUrl);
      return rule.getString(source.ruleContent!);
    }
    return body; // 預設返回原始 HTML
  }
}


import 'package:legado_reader/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/models/rss_article.dart';
import 'package:legado_reader/core/models/rss_star.dart';
import 'package:legado_reader/core/database/dao/rss_star_dao.dart';
import 'package:legado_reader/core/services/rss_parser.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

class RssArticleProvider extends ChangeNotifier {
  final RssSource source;
  final RssStarDao _starDao = getIt<RssStarDao>();
  
  List<RssArticle> _articles = [];
  Set<String> _starredLinks = {};
  bool _isLoading = false;
  int _page = 1;
  String? _nextPageUrl;

  List<RssArticle> get articles => _articles;
  bool get isLoading => _isLoading;
  bool get hasMore => _nextPageUrl != null || _page == 1;

  RssArticleProvider(this.source) {
    _init();
  }

  Future<void> _init() async {
    await loadStarred();
    await loadArticles();
  }

  Future<void> loadStarred() async {
    final starred = await _starDao.getAll();
    _starredLinks = starred.map((e) => e.link).toSet();
    notifyListeners();
  }

  bool isStarred(RssArticle article) => _starredLinks.contains(article.link);

  Future<void> toggleStar(RssArticle article) async {
    if (isStarred(article)) {
      await _starDao.deleteByLink(article.origin, article.link);
      _starredLinks.remove(article.link);
    } else {
      final star = RssStar(
        origin: article.origin,
        link: article.link,
        title: article.title,
        pubDate: article.pubDate,
        description: article.description,
        image: article.image,
        starTime: DateTime.now().millisecondsSinceEpoch,
      );
      await _starDao.upsert(star);
      _starredLinks.add(article.link);
    }
    notifyListeners();
  }

  Future<void> loadArticles({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _articles = [];
      _nextPageUrl = null;
    }

    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final url = _nextPageUrl ?? source.sourceUrl;
      final analyzer = AnalyzeRule(source: source);
      final analyzeUrl = AnalyzeUrl(
        url,
        page: _page,
        baseUrl: source.sourceUrl,
        source: source,
      );

      final body = await analyzeUrl.getResponseBody();
      if (body.isNotEmpty) {
        final newArticles = await RssParser.parseArticles(
          source,
          body,
          analyzeUrl.url,
        );
        _articles.addAll(newArticles);

        // 處理下一頁
        if (source.ruleNextPage != null && source.ruleNextPage!.isNotEmpty) {
          final rule = analyzer.setContent(body, baseUrl: analyzeUrl.url);
          _nextPageUrl = rule.getString(source.ruleNextPage!, isUrl: true);
        } else {
          _nextPageUrl = null;
        }
        _page++;
      }
    } catch (e) {
      debugPrint('加載 RSS 文章失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


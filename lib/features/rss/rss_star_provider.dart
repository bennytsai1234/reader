import 'package:legado_reader/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/database/dao/rss_star_dao.dart';
import 'package:legado_reader/core/models/rss_star.dart';

class RssStarProvider extends ChangeNotifier {
  final RssStarDao _dao = getIt<RssStarDao>();
  List<RssStar> _stars = [];
  bool _isLoading = false;

  List<RssStar> get stars => _stars;
  bool get isLoading => _isLoading;

  RssStarProvider() {
    loadStars();
  }

  Future<void> loadStars() async {
    _isLoading = true;
    notifyListeners();
    try {
      _stars = await _dao.getAll();
    } catch (e) {
      debugPrint('加載 RSS 收藏失敗: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStar(RssStar star) async {
    await _dao.deleteByLink(star.origin, star.link);
    await loadStars();
  }
}


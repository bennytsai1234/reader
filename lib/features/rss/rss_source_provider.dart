import 'package:legado_reader/core/di/injection.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/database/dao/rss_source_dao.dart';
import 'package:legado_reader/core/models/rss_source.dart';

class RssSourceProvider extends ChangeNotifier {
  final RssSourceDao _dao = getIt<RssSourceDao>();
  List<RssSource> _sources = [];
  bool _isLoading = false;
  final String _currentGroup = '全部';
  int _unreadCount = 0;

  List<RssSource> get sources => _sources;
  bool get isLoading => _isLoading;
  String get currentGroup => _currentGroup;
  int get unreadCount => _unreadCount;

  RssSourceProvider() {
    loadSources();
  }

  Future<void> loadSources() async {
    _isLoading = true;
    notifyListeners();
    _sources = await _dao.getAll();
    
    // 模擬計算未讀數量 (實際開發應從 RssArticleDao 查詢已讀/未讀狀態)
    // 目前我們先模擬一個隨機數值或固定數值，以讓主框架功能完整
    _unreadCount = _sources.where((s) => s.enabled).length * 3; 

    _isLoading = false;
    notifyListeners();
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> toggleEnabled(RssSource source) async {
    final newState = !source.enabled;
    await _dao.updateEnabled(source.sourceUrl, newState);
    source.enabled = newState;
    notifyListeners();
  }

  Future<void> deleteSource(String url) async {
    await _dao.delete(url);
    await loadSources();
  }

  Future<int> importFromJson(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr);
      final list = data is List ? data : [data];
      var count = 0;
      for (var item in list) {
        final source = RssSource.fromJson(item);
        await _dao.upsert(source);
        count++;
      }
      await loadSources();
      return count;
    } catch (e) {
      debugPrint('從 JSON 匯入 RSS 失敗: $e');
      return 0;
    }
  }

  Future<int> importFromUrl(String url) async {
    try {
      final response = await Dio().get(url);
      if (response.data != null) {
        final List<dynamic> jsonList = response.data is String 
          ? jsonDecode(response.data) 
          : response.data;
        
        var count = 0;
        for (final item in jsonList) {
          final source = RssSource.fromJson(item);
          await _dao.upsert(source);
          count++;
        }
        await loadSources();
        return count;
      }
    } catch (e) {
      debugPrint('匯入 RSS 來源失敗: $e');
    }
    return 0;
  }
}


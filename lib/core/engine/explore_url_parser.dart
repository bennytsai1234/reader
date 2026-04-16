import 'dart:convert';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/engine/analyze_rule.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/source/explore_kind.dart';

/// ExploreUrlParser - 發現規則解析器 (對標 Android BookSource.getExploreKinds)
class ExploreUrlParser {
  /// 將 exploreUrl 字符串解析為分類列表
  /// 支援 JS 動態規則 (`@js:` 或 `<js>...</js>`)
  /// 支援 JSON 陣列格式
  static List<ExploreKind> parse(String? exploreUrl, {BookSource? source}) {
    if (exploreUrl == null || exploreUrl.isEmpty) return [];

    var urlStr = exploreUrl;

    try {
      // 處理 JS 動態發現規則 (對標 Android BookSource.getExploreKinds)
      if (urlStr.startsWith('<js>') || urlStr.startsWith('@js:')) {
        if (source != null) {
          final jsStr = urlStr.startsWith('@js:')
              ? urlStr.substring(4)
              : urlStr.substring(4, urlStr.lastIndexOf('<'));
          final rule = AnalyzeRule(source: source);
          final result = rule.evalJS(jsStr.trim(), null);
          if (result != null && result.toString().isNotEmpty) {
            urlStr = result.toString().trim();
          } else {
            return [];
          }
        } else {
          // 沒有 source context 時無法執行 JS
          return [];
        }
      }
    } catch (e) {
      AppLog.e('ExploreUrl JS 執行失敗: $e', error: e);
      return [ExploreKind(title: 'ERROR:${e.toString()}', url: e.toString())];
    }

    // 嘗試 JSON 陣列格式 (對標 Android isJsonArray)
    if (_isJsonArray(urlStr)) {
      return _parseJsonArray(urlStr);
    }

    return _parseStatic(urlStr);
  }

  /// 檢查是否為 JSON 陣列
  static bool _isJsonArray(String str) {
    final trimmed = str.trim();
    return trimmed.startsWith('[') && trimmed.endsWith(']');
  }

  /// 解析 JSON 陣列格式的 exploreUrl
  static List<ExploreKind> _parseJsonArray(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => ExploreKind.fromJson(e))
          .toList();
    } catch (e) {
      AppLog.e('ExploreUrl JSON 解析失敗: $e', error: e);
      return [ExploreKind(title: 'ERROR:${e.toString()}', url: e.toString())];
    }
  }

  /// 解析靜態格式的 exploreUrl (對標 Android `&&` 和 `\n` 分隔)
  static List<ExploreKind> _parseStatic(String exploreUrl) {
    final List<ExploreKind> kinds = [];

    try {
      // 使用 && 或換行符分隔 (對標 Android `(&&|\n)+`.toRegex())
      final items = exploreUrl.split(RegExp(r'(&&|\n)+'));
      for (var item in items) {
        final trimmed = item.trim();
        if (trimmed.isEmpty) continue;

        // 解析標題與網址 (::)
        final parts = trimmed.split('::');
        if (parts.length >= 2) {
          kinds.add(ExploreKind(
            title: parts[0].trim(),
            url: parts.sublist(1).join('::').trim(),
          ));
        }
      }
    } catch (e) {
      AppLog.e('ExploreUrl解析失敗: $e', error: e);
      kinds.add(ExploreKind(title: 'ERROR:${e.toString()}', url: e.toString()));
    }

    return kinds;
  }
}

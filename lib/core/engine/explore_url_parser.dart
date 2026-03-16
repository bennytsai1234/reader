import 'package:flutter/foundation.dart';

/// ExploreKind - 探索分類模型 (對標 Android ExploreKind)
class ExploreKind {
  final String title;
  final String url;
  final String? group;

  ExploreKind({required this.title, required this.url, this.group});
}

/// ExploreUrlParser - 發現規則解析器 (對標 Android BookSource.getExploreKinds)
class ExploreUrlParser {
  /// 將 exploreUrl 字符串解析為分類列表
  static List<ExploreKind> parse(String? exploreUrl) {
    if (exploreUrl == null || exploreUrl.isEmpty) return [];
    
    final List<ExploreKind> kinds = [];
    
    try {
      // 1. 處理分組 (||)
      final groups = exploreUrl.split(RegExp(r'\s*\|\|\s*'));
      for (var groupStr in groups) {
        // 2. 處理分類 (&& 或 \n)
        final items = groupStr.split(RegExp(r'\s*&&\s*|\n'));
        for (var item in items) {
          if (item.trim().isEmpty) continue;
          
          // 3. 解析標題與網址 (::)
          final parts = item.split('::');
          if (parts.length >= 3) {
            // 帶分組格式: 分組::標題::網址
            kinds.add(ExploreKind(group: parts[0].trim(), title: parts[1].trim(), url: parts[2].trim()));
          } else if (parts.length == 2) {
            // 普通格式: 標題::網址
            kinds.add(ExploreKind(title: parts[0].trim(), url: parts[1].trim()));
          }
        }
      }
    } catch (e) {
      debugPrint('ExploreUrl解析失敗: $e');
    }
    
    return kinds;
  }
}

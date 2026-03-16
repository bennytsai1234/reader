import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import 'package:legado_reader/core/services/chinese_utils.dart';
import 'package:legado_reader/core/constant/app_pattern.dart';

/// ContentProcessor - 閱讀器正文處理引擎 (效能優化版)
class ContentProcessor {
  
  /// 異步處理正文 (自動切換 Isolate 防止 UI 阻塞)
  static Future<String> process({
    required Book book,
    required BookChapter chapter,
    required String rawContent,
    required List<ReplaceRule> rules,
    int chineseConvertType = 0,
    bool reSegmentEnabled = true,
    bool removeSameTitle = true,
  }) async {
    if (rawContent.isEmpty) return '';

    // 1. 在 Isolate 中執行 CPU 密集型操作 (正則替換、分段)
    var processedContent = await compute(_internalProcess, {
      'bookName': book.name,
      'bookOrigin': book.origin,
      'chapterTitle': chapter.title,
      'rawContent': rawContent,
      'rules': rules,
      'reSegmentEnabled': reSegmentEnabled,
      'removeSameTitle': removeSameTitle,
    });

    // 2. 簡繁轉換 (這部分通常已經是異步插件實現，或在此處繼續處理)
    if (chineseConvertType == 1) {
      processedContent = await ChineseUtils.t2s(processedContent);
    } else if (chineseConvertType == 2) {
      processedContent = await ChineseUtils.s2t(processedContent);
    }

    return processedContent.trim();
  }

  /// 內部同步處理邏輯 (Isolate 友善)
  static String _internalProcess(Map<String, dynamic> args) {
    final String bookName = args['bookName'];
    final String bookOrigin = args['bookOrigin'];
    final String chapterTitle = args['chapterTitle'];
    final String rawContent = args['rawContent'];
    final List<ReplaceRule> rules = args['rules'];
    final bool reSegmentEnabled = args['reSegmentEnabled'];
    final bool removeSameTitle = args['removeSameTitle'];

    var result = rawContent;

    if (removeSameTitle) {
      result = _removeSameTitle(result, chapterTitle, bookName);
    }

    if (reSegmentEnabled) {
      result = _reSegment(result);
    }

    result = _applyRules(result, bookName, bookOrigin, rules);

    return result;
  }

  static String _removeSameTitle(String content, String title, String bookName) {
    try {
      final titleStr = RegExp.escape(title).replaceAll(AppPattern.spaceRegex, r'\s*');
      final nameStr = RegExp.escape(bookName);
      final pattern = RegExp('^(\\s|\\p{P}|$nameStr)*$titleStr(\\s)*', unicode: true);
      
      final match = pattern.firstMatch(content);
      if (match != null) {
        return content.substring(match.end);
      }
    } catch (_) {}
    return content;
  }

  static String _reSegment(String content) {
    final paragraphs = content.split(RegExp(r'\n+'));
    final result = <String>[];

    for (var p in paragraphs) {
      final text = p.trim().replaceAll(RegExp(r'[\u3000\s]+'), ' ').trim();
      if (text.isEmpty) continue;
      result.add(text);
    }
    
    return result.join('\n');
  }

  static String _applyRules(String content, String bookName, String bookOrigin, List<ReplaceRule> rules) {
    var result = content;
    final stopwatch = Stopwatch()..start();
    const timeout = Duration(seconds: 2); // 規則替換超時保護

    for (final rule in rules) {
      if (!rule.isEnabled || !rule.scopeContent) continue;
      if (stopwatch.elapsed > timeout) break;

      if (rule.scope?.isNotEmpty == true) {
        if (!rule.scope!.contains(bookName) && !rule.scope!.contains(bookOrigin)) continue;
      }

      try {
        if (rule.isRegex) {
          final reg = RegExp(rule.pattern, multiLine: true, dotAll: true);
          result = result.replaceAllMapped(reg, (match) {
            return rule.replacement.replaceAllMapped(RegExp(r'\\\$|\$(\d+)'), (m) {
              final hit = m.group(0)!;
              if (hit == r'\$') return r'$';
              final idx = int.tryParse(m.group(1)!) ?? 0;
              return (idx > 0 && idx <= match.groupCount) ? (match.group(idx) ?? '') : hit;
            });
          });
        } else {
          result = result.replaceAll(rule.pattern, rule.replacement);
        }
      } catch (_) {}
    }
    return result;
  }
}


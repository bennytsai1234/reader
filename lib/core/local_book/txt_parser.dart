import 'dart:io';
import '../services/encoding_detect.dart';

/// TxtParser - 高性能 TXT 解析器
/// 深度還原 Android model/localBook/TextFile.kt 的物理分割邏輯
class TxtParser {
  final File file;
  
  // 深度還原：單個虛擬章節的最大字元數 (約 40KB)，避免 SQLite CursorWindow 溢出
  static const int maxChapterChars = 20000;

  static final RegExp defaultChapterPattern = RegExp(
    r'^.{0,10}[第][0-9零一二两三四五六七八九十百千万万]+[章回节卷集幕计][ \t]*.*',
    multiLine: true,
  );

  TxtParser(this.file);

  /// preliminary scan (if needed in future)
  Future<void> load() async {}

  /// 深度還原：支援物理分割的章節切割邏輯
  Future<List<Map<String, String>>> splitChapters({RegExp? customPattern}) async {
    final pattern = customPattern ?? defaultChapterPattern;
    final bytes = await file.readAsBytes();
    final content = EncodingDetect.decode(bytes);
    
    final result = <Map<String, String>>[];
    final matches = pattern.allMatches(content).toList();

    if (matches.isEmpty) {
      return _splitLargeContent('正文', content);
    }

    // 處理前言
    if (matches.first.start > 0) {
      result.addAll(_splitLargeContent('前言', content.substring(0, matches.first.start)));
    }

    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final title = matches[i].group(0)?.trim() ?? '第 ${i + 1} 章';
      final chapterContent = content.substring(start, end).trim();
      
      // 深度還原：物理分割邏輯
      result.addAll(_splitLargeContent(title, chapterContent));
    }

    return result;
  }

  /// 深度還原：將單個超大內容區塊物理分割為多個虛擬章節
  List<Map<String, String>> _splitLargeContent(String title, String content) {
    if (content.length <= maxChapterChars) {
      return [{'title': title, 'content': content}];
    }

    final chunks = <Map<String, String>>[];
    var count = 1;
    for (var i = 0; i < content.length; i += maxChapterChars) {
      final end = (i + maxChapterChars < content.length) ? i + maxChapterChars : content.length;
      chunks.add({
        'title': '$title (${count++})',
        'content': content.substring(i, end),
      });
    }
    return chunks;
  }
}


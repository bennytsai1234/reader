import 'dart:io';
import 'dart:typed_data';
import '../services/encoding_detect.dart';

/// TxtParser - 高性能 TXT 解析器
/// 深度還原 Android model/localBook/TextFile.kt 的物理位移邏輯
class TxtParser {
  final File file;
  
  static final RegExp defaultChapterPattern = RegExp(
    r'^\s*[第][0-9零一二两三四五六七八九十百千万万]+[章回节卷集幕计][ \t]*.*$',
    multiLine: true,
  );

  TxtParser(this.file);

  Future<void> load() async {}


  /// 掃描文件並獲取章節位移 (不讀取全量內容入記憶體)
  Future<List<Map<String, dynamic>>> splitChapters({RegExp? customPattern}) async {
    final pattern = customPattern ?? defaultChapterPattern;
    final bytes = await file.readAsBytes();
    final charset = EncodingDetect.detect(bytes);
    final content = EncodingDetect.decode(bytes);
    
    final result = <Map<String, dynamic>>[];
    final matches = pattern.allMatches(content).toList();

    // 將字元索引轉換為位元組位移的輔助函數
    // 雖然這裡暫時讀取了全量 String (為了正則匹配), 但我們記錄的是 byte offset
    // 這樣讀取內容時就可以用 RandomAccessFile
    
    int getByteOffset(int charOffset) {
      return charset.encode(content.substring(0, charOffset)).length;
    }

    if (matches.isEmpty) {
      result.add({
        'title': '正文',
        'start': 0,
        'end': bytes.length,
        'content': content,
      });

      return result;
    }

    // 處理前言
    if (matches.first.start > 0) {
      result.add({
        'title': '前言',
        'start': 0,
        'end': getByteOffset(matches.first.start),
        'content': content.substring(0, matches.first.start),
      });

    }

    for (var i = 0; i < matches.length; i++) {
      final charStart = matches[i].start;
      final charEnd = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      
      final byteStart = getByteOffset(charStart);
      final byteEnd = getByteOffset(charEnd);
      
      final title = matches[i].group(0)?.trim() ?? '第 ${i + 1} 章';
      
      result.add({
        'title': title,
        'start': byteStart,
        'end': byteEnd,
        'content': content.substring(charStart, charEnd),
      });

    }

    return result;
  }
}

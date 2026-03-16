import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// QueryTTF - 字體解析與偏移處理 (原 Android QueryTTF.java)
/// 負責處理某些書源自定義字體的動態對映
class QueryTTF {
  final Uint8List fontData;
  final Map<int, Uint8List> _glyfCache = {};
  final Map<int, int> _unicodeToGlyfId = {};
  final Map<String, int> _glyfHashToUnicode = {};

  QueryTTF(this.fontData) {
    _parseFont();
  }

  void _parseFont() {
    // 這裡應實作簡化的 TTF 解析邏輯 (CMap, Glyf table)
    // 由於 Dart 中缺乏成熟的低階字體解析庫，此處先提供框架
    // 未來可整合 OpenType.js 的 Dart 移植版或透過 Native Channel
  }

  /// 檢查是否為空白字元
  bool isBlankUnicode(int codePoint) {
    // 簡單判斷常見空白
    return codePoint <= 32 || codePoint == 160 || codePoint == 12288;
  }

  /// 獲取字形的輪廓數據 (Glyf)
  Uint8List? getGlyfByUnicode(int codePoint) {
    final glyfId = _unicodeToGlyfId[codePoint];
    if (glyfId == null) return null;
    return _glyfCache[glyfId];
  }

  /// 根據輪廓數據反查 Unicode
  int getUnicodeByGlyf(Uint8List? glyf) {
    if (glyf == null) return 0;
    final hash = md5.convert(glyf).toString();
    return _glyfHashToUnicode[hash] ?? 0;
  }

  /// 執行字體替換邏輯 (對標 JsExtensions.replaceFont)
  static String replaceFont(String text, QueryTTF? errorFont, QueryTTF? correctFont, {bool filter = false}) {
    if (errorFont == null || correctFont == null) return text;
    
    final List<int> codePoints = text.runes.toList();
    final List<int> result = [];

    for (var code in codePoints) {
      if (errorFont.isBlankUnicode(code)) {
        result.add(code);
        continue;
      }

      final glyf = errorFont.getGlyfByUnicode(code);
      if (glyf == null) {
        if (!filter) result.add(code);
        continue;
      }

      final correctCode = correctFont.getUnicodeByGlyf(glyf);
      if (correctCode != 0) {
        result.add(correctCode);
      } else if (!filter) {
        result.add(code);
      }
    }

    return String.fromCharCodes(result);
  }
}


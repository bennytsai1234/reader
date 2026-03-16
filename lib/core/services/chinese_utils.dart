import 'package:flutter_open_chinese_convert/flutter_open_chinese_convert.dart';

/// ChineseUtils - 簡繁轉換工具
/// 整合 OpenCC (Open Chinese Convert) 確保精準的上下文詞彙轉換
/// 解決「一對多」映射問題（如：发 -> 發/髮, 后 -> 後/后）
class ChineseUtils {
  ChineseUtils._();

  /// 簡體轉繁體 (預設使用 S2T 模式)
  /// 如果需要台灣慣用語轉換，可改用 S2TWp()
  static Future<String> s2t(String text) async {
    if (text.isEmpty) return text;
    return await ChineseConverter.convert(text, S2T());
  }

  /// 繁體轉簡體 (預設使用 T2S 模式)
  static Future<String> t2s(String text) async {
    if (text.isEmpty) return text;
    return await ChineseConverter.convert(text, T2S());
  }
}


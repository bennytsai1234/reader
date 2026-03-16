/// MOBI 解析器 (佔位符)
/// (原 Android model/localBook/MobiFile.kt)
/// 
/// 診斷：MOBI 格式較為陳舊且複雜，Dart 生態中缺乏成熟的純 Dart 解析庫。
/// 建議後續透過 FFI 整合開源的 C/Rust 解析器。
class MobiParser {
  static Future<void> parse(String filePath) async {
    throw UnsupportedError('目前版本尚未支援 MOBI 本地解析，請期待後續更新。');
  }
}


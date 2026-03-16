/// PDF 解析器 (佔位符)
/// (原 Android model/localBook/PdfFile.kt)
/// 
/// 診斷：Flutter 尚未實作原生 PDF 文本提取。若需支援，
/// 建議使用 `syncfusion_flutter_pdf` 或透過 FFI 呼叫 Rust/C++ 庫。
class PdfParser {
  static Future<void> parse(String filePath) async {
    throw UnsupportedError('目前版本尚未支援 PDF 本地解析，請期待後續更新。');
  }
}


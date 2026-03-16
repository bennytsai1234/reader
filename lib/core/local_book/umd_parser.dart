import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../models/book.dart';
import '../models/chapter.dart';

/// UmdParser - UMD 格式解析器
/// (原 Android modules/book/umdlib)
class UmdParser {
  static Future<Map<String, dynamic>> parse(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final reader = _ByteReader(bytes);

    // 1. 魔數檢查 (0xde9a9b89)
    if (reader.readUint32() != 0xde9a9b89) {
      throw Exception('不是有效的 UMD 檔案');
    }

    var title = '';
    var author = '';
    final chapters = <BookChapter>[];

    while (!reader.isEnd) {
      final ch = reader.readByte();
      if (ch == 0x23) { // '#' 塊
        final type = reader.readUint16();
        reader.readByte(); // flag
        final len = reader.readByte() - 5;

        switch (type) {
          case 2: // 標題
            title = _decodeUnicode(reader.readBytes(len));
            break;
          case 3: // 作者
            author = _decodeUnicode(reader.readBytes(len));
            break;
          case 11: // 總長度
            reader.readUint32();
            break;
        }
      } else if (ch == 0x24) { // '$' 附加塊
        reader.readUint32(); // addCheck
        final typeLen = reader.readUint32() - 9;
        // 附加內容解析邏輯 (目前略過)
        if (typeLen > 0) reader.skip(typeLen);
      }
      
      if (reader.pos > bytes.length - 10) break;
    }

    return {
      'book': Book(
        bookUrl: filePath,
        origin: 'local',
        name: title.isEmpty ? file.path.split('/').last : title,
        author: author,
      ),
      'chapters': chapters,
    };
  }

  static String _decodeUnicode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }
}

class _ByteReader {
  final Uint8List _bytes;
  int pos = 0;

  _ByteReader(this._bytes);

  bool get isEnd => pos >= _bytes.length;

  int readByte() => _bytes[pos++];

  int readUint16() {
    if (pos + 2 > _bytes.length) return 0;
    final val = _bytes[pos] | (_bytes[pos + 1] << 8);
    pos += 2;
    return val;
  }

  int readUint32() {
    if (pos + 4 > _bytes.length) return 0;
    final val = _bytes[pos] | (_bytes[pos + 1] << 8) | (_bytes[pos + 2] << 16) | (_bytes[pos + 3] << 24);
    pos += 4;
    return val;
  }

  List<int> readBytes(int len) {
    if (pos + len > _bytes.length) len = _bytes.length - pos;
    final res = _bytes.sublist(pos, pos + len);
    pos += len;
    return res;
  }

  void skip(int len) {
    pos += len;
    if (pos > _bytes.length) pos = _bytes.length;
  }
}


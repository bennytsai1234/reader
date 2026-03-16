import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'dart:convert';
import '../js_extensions_base.dart';
import '../js_encode_utils.dart';
import 'package:legado_reader/core/services/http_client.dart';
import 'package:legado_reader/core/services/encoding_detect.dart';

/// JsExtensions 的文件 IO 與壓縮處理擴展
extension JsFileExtensions on JsExtensionsBase {
  void injectFileExtensions() {
    runtime.onMessage('downloadFile', (dynamic args) async {
      final url = args.toString();
      try {
        final key = JsEncodeUtils.md5Encode16(url);
        final tempDir = await getTemporaryDirectory();
        final savePath = p.join(tempDir.path, 'downloads', key);
        final file = File(savePath);
        if (!await file.parent.exists()) await file.parent.create(recursive: true);
        await HttpClient().client.download(url, savePath);
        return savePath;
      } catch (_) { return ''; }
    });

    runtime.onMessage('readFile', (dynamic args) async {
      final file = File(args.toString());
      return await file.exists() ? await file.readAsBytes() : null;
    });

    runtime.onMessage('readTxtFile', (dynamic args) async {
      final path = args.toString();
      final charset = args is List && args.length > 1 ? args[1].toString() : 'UTF-8';
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (charset.toUpperCase().contains('GBK') || charset.toUpperCase().contains('GB2312')) return gbk.decode(bytes);
        return utf8.decode(bytes, allowMalformed: true);
      }
      return '';
    });

    runtime.onMessage('unArchiveFile', (dynamic args) async {
      try {
        final relPath = args.toString();
        final file = File(p.join((await getApplicationDocumentsDirectory()).path, relPath));
        if (!await file.exists()) return '';
        final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
        final tempDir = await getTemporaryDirectory();
        final outPath = p.join(tempDir.path, 'ArchiveTemp', JsEncodeUtils.md5Encode16(file.path));
        for (final entry in archive) {
          if (entry.isFile) {
            final data = entry.content as List<int>;
            File(p.join(outPath, entry.name))..createSync(recursive: true)..writeAsBytesSync(data);
          }
        }
        return p.relative(outPath, from: tempDir.path);
      } catch (_) { return ''; }
    });

    runtime.onMessage('getTxtInFolder', (dynamic args) async {
      try {
        final relPath = args.toString();
        final tempDir = await getTemporaryDirectory();
        final folder = Directory(p.join(tempDir.path, relPath));
        if (!await folder.exists()) return '';
        final buffer = StringBuffer();
        final files = folder.listSync().whereType<File>().toList();
        for (var f in files) {
          final bytes = await f.readAsBytes();
          final content = EncodingDetect.getEncode(bytes) == 'GBK' ? gbk.decode(bytes) : utf8.decode(bytes, allowMalformed: true);
          buffer.writeln(content);
        }
        return buffer.toString();
      } catch (_) { return ''; }
    });
  }
}


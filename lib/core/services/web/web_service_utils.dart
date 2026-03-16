import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:legado_reader/core/models/book_progress.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/engine/app_event_bus.dart';
import 'web_service_base.dart';

/// WebService 的工具與輔助邏輯擴展
extension WebServiceUtils on WebServiceBase {
  /// 獲取本地 IP
  Future<String> getLocalIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  /// 處理 WebSocket
  void handleWebSocket(HttpRequest request) async {
    try {
      final socket = await WebSocketTransformer.upgrade(request);
      webSockets.add(socket);
      socket.listen(
        (data) => debugPrint('WebSocket received: $data'),
        onDone: () => webSockets.remove(socket),
        onError: (e) => webSockets.remove(socket),
      );
    } catch (e) {
      debugPrint('WebSocket upgrade failed: $e');
    }
  }

  /// 廣播日誌
  void broadcastLog(Map<String, dynamic> logData) {
    final json = jsonEncode(logData);
    for (var socket in webSockets) {
      if (socket.readyState == WebSocket.open) socket.add(json);
    }
  }

  /// 處理本地書籍上傳
  Future<String> handleAddLocalBook(HttpRequest request) async {
    final contentType = request.headers.contentType;
    final boundary = contentType?.parameters['boundary'];
    if (boundary == null) throw Exception('No boundary found in multipart');

    final boundaryBytes = utf8.encode('--$boundary');
    final data = await request.expand((b) => b).toList();

    var start = _indexOfBytes(data, boundaryBytes, 0);
    if (start == -1) throw Exception('Invalid multipart format');
    start += boundaryBytes.length + 2;

    final headerEnd = _indexOfBytes(data, utf8.encode('\r\n\r\n'), start);
    if (headerEnd == -1) throw Exception('Invalid headers');
    
    final headerStr = utf8.decode(data.sublist(start, headerEnd));
    var fileName = 'upload.txt';
    final match = RegExp(r'filename="([^"]+)"').firstMatch(headerStr);
    if (match != null) fileName = match.group(1)!;

    final contentStart = headerEnd + 4;
    final contentEnd = _indexOfBytes(data, boundaryBytes, contentStart) - 2;

    final fileData = data.sublist(contentStart, contentEnd);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(fileData);

    AppEventBus().fire('importLocalBook', data: file.path);
    return 'File uploaded to ${file.path}. Import triggered.';
  }

  int _indexOfBytes(List<int> data, List<int> pattern, int start) {
    for (var i = start; i <= data.length - pattern.length; i++) {
      var match = true;
      for (var j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  /// 處理其餘 POST 請求 (邏輯過長，移至 Utils)
  Future<dynamic> handlePostExtended(String path, String body) async {
    switch (path) {
      case '/saveBookProgress':
        final progress = BookProgress.fromJson(jsonDecode(body));
        final book = await bookDao.getByNameAndAuthor(progress.name, progress.author);
        if (book != null) {
          await bookDao.updateProgress(book.bookUrl, progress.durChapterPos);
          return '';
        }
        return null;
      case '/saveReplaceRule':
        final rule = ReplaceRule.fromJson(jsonDecode(body));
        await replaceDao.upsert(rule);
        return '';
      case '/deleteReplaceRule':
        final rule = ReplaceRule.fromJson(jsonDecode(body));
        await replaceDao.deleteById(rule.id);
        return '';
      case '/saveRssSource':
        final source = RssSource.fromJson(jsonDecode(body));
        await rssDao.upsert(source);
        return '';
      default:
        return null;
    }
  }
}


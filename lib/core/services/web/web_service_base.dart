import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/database/dao/rss_source_dao.dart';
import '../book_source_service.dart';
import 'package:legado_reader/core/di/injection.dart';

/// WebService 基礎類別與單例結構
abstract class WebServiceBase extends ChangeNotifier {
   // 由子類實現單例

  HttpServer? server;
  bool isRunning = false;
  int port = 8659;
  String? ipAddress;

  final BookDao bookDao = getIt<BookDao>();
  final BookSourceDao sourceDao = getIt<BookSourceDao>();
  final ChapterDao chapterDao = getIt<ChapterDao>();
  final ReplaceRuleDao replaceDao = getIt<ReplaceRuleDao>();
  final RssSourceDao rssDao = getIt<RssSourceDao>();
  final BookSourceService sourceService = BookSourceService();

  final List<WebSocket> webSockets = [];

  Future<void> startServer({int port = 8659, required Function(HttpRequest) handler, required Future<String> Function() getIp}) async {
    if (isRunning) return;
    try {
      this.port = port;
      server = await HttpServer.bind(InternetAddress.anyIPv4, this.port);
      isRunning = true;
      ipAddress = await getIp();
      server!.listen(handler);
      debugPrint('WebService started at http://$ipAddress:$port');
      notifyListeners();
    } catch (e) {
      debugPrint('WebService failed to start: $e');
      isRunning = false;
      notifyListeners();
    }
  }

  Future<void> stopServer() async {
    await server?.close(force: true);
    server = null;
    isRunning = false;
    ipAddress = null;
    notifyListeners();
  }
}



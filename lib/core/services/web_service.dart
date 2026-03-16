import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:legado_reader/core/network/api/source_controller.dart';
import 'package:legado_reader/core/network/api/book_controller.dart';
import 'package:legado_reader/core/utils/logger.dart';

class WebService {
  static final WebService _instance = WebService._internal();
  factory WebService() => _instance;
  WebService._internal();

  HttpServer? _server;
  final _sourceController = SourceController();
  final _bookController = BookController();

  bool get isRunning => _server != null;

  Future<String?> getLocalIp() async {
    return await NetworkInfo().getWifiIP();
  }

  /// 釋放 Web Assets 到臨時目錄
  Future<String> _prepareWebAssets() async {
    final tempDir = await getTemporaryDirectory();
    final webPath = '${tempDir.path}/web_assets';
    final directory = Directory(webPath);
    
    // 如果目錄不存在，建立它並嘗試釋放資產
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
      try {
        // Flutter asset 清單通常很難動態獲取，這裡我們採用寫入一個基礎 index.html 的方案
        // 或者是從 pubspec.yaml 的清單中預期檔案。
        // 目前我們先確保基礎文件存在，以防止 Shelf 崩潰
        final indexFile = File('$webPath/index.html');
        if (!indexFile.existsSync()) {
          await indexFile.writeAsString('<html><body><h1>Legado Reader Web Service</h1></body></html>');
        }
      } catch (e) {
        Logger.e('釋放 Web Assets 失敗: $e');
      }
    }
    return webPath;
  }

  Future<void> start({int port = 1122}) async {
    if (_server != null) return;

    final webPath = await _prepareWebAssets();
    final router = Router();
    
    // ... (路由不變)

    // API 路由(原 Android HttpServer.kt)
    router.get('/getBookSources', (Request request) async {
      final res = await _sourceController.getSources();
      return Response.ok(res.toString(), headers: {'Content-Type': 'application/json'});
    });

    router.post('/saveBookSource', (Request request) async {
      final body = await request.readAsString();
      final res = await _sourceController.saveSource(body);
      return Response.ok(res.toString(), headers: {'Content-Type': 'application/json'});
    });

    router.get('/getBookshelf', (Request request) async {
      final res = await _bookController.getBookshelf();
      return Response.ok(res.toString(), headers: {'Content-Type': 'application/json'});
    });

    // 靜態資源託管 (Web UI)
    final staticHandler = createStaticHandler(webPath, defaultDocument: 'index.html');
    
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addHandler((Request request) {
          if (request.url.path.startsWith('getBook') || request.url.path.startsWith('save')) {
            return router(request);
          }
          return staticHandler(request);
        });

    try {
      _server = await io.serve(handler, InternetAddress.anyIPv4, port);
      Logger.i('Web 服務啟動於: http://${await getLocalIp()}:$port');
    } catch (e) {
      Logger.e('Web 服務啟動失敗: $e');
      _server = null;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    Logger.i('Web 服務已關閉');
  }

  void broadcastLog(dynamic log) {
    // 實作 broadcastLog，原本 Android 用於向 Web 端推送日誌
    // 這裡我們先列印，未來可搭配 WebSocket 實作
    Logger.d('WebService Log: $log');
  }

  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
          });
        }
        final response = await innerHandler(request);
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
        });
      };
    };
  }
}


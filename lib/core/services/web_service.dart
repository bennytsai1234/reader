import 'dart:io';
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

  Future<void> start({int port = 1122}) async {
    if (_server != null) return;

    final router = Router();

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
    // 注意：Flutter assets 需要特殊處理或先解壓到臨時目錄，這裡採用 shelf_static 配合本地目錄
    // 實際上 Legado 的 Web 資源在 assets/web，我們假設已同步至該位置
    final staticHandler = createStaticHandler('assets/web', defaultDocument: 'index.html');
    
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


import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:legado_reader/core/utils/logger.dart';

class HeadlessWebViewService {
  static final HeadlessWebViewService _instance = HeadlessWebViewService._internal();
  factory HeadlessWebViewService() => _instance;
  HeadlessWebViewService._internal();

  HeadlessInAppWebView? _headlessWebView;

  /// 獲取網頁渲染後的 HTML
  Future<String> getRenderedHtml({
    required String url,
    Map<String, String>? headers,
    String? userAgent,
    String? js,
    int delayTime = 0,
  }) async {
    final completer = Completer<String>();
    
    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(url),
        headers: headers,
      ),
      initialSettings: InAppWebViewSettings(
        userAgent: userAgent,
        javaScriptEnabled: true,
        useShouldInterceptRequest: true,
      ),
      onLoadStop: (controller, webUri) async {
        // 如果有延遲要求，先等待
        if (delayTime > 0) {
          await Future.delayed(Duration(milliseconds: delayTime));
        }

        // 執行額外的 JS 腳本
        if (js != null && js.isNotEmpty) {
          try {
            await controller.evaluateJavascript(source: js);
          } catch (e) {
            Logger.e('WebView JS 執行失敗: $e');
          }
        }

        // 獲取最終 HTML ((原 Android document.documentElement.outerHTML))
        final html = await controller.evaluateJavascript(source: 'document.documentElement.outerHTML');
        completer.complete(html?.toString() ?? '');
      },
      onReceivedError: (controller, request, error) {
        completer.completeError('WebView 加載失敗: ${error.description} (代碼: ${error.type})');
      },
    );

    try {
      await _headlessWebView?.run();
      final result = await completer.future;
      return result;
    } finally {
      await _headlessWebView?.dispose();
      _headlessWebView = null;
    }
  }
}


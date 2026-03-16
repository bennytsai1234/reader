import 'dart:async';
import 'dart:io' as io;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'network_service.dart';

/// WebViewManager - 處理網頁挑戰與 Cookie 同步
/// 用於解決 Cloudflare 與複雜 JS 驗證
class WebViewManager {
  static final WebViewManager _instance = WebViewManager._internal();
  factory WebViewManager() => _instance;
  WebViewManager._internal();

  HeadlessInAppWebView? _headlessWebView;
  final CookieManager _webviewCookieManager = CookieManager.instance();

  /// 靜默解決網頁挑戰並同步 Cookie
  Future<bool> solveChallenge(String url) async {
    final completer = Completer<bool>();
    
    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        javaScriptEnabled: true,
      ),
      onLoadStop: (controller, url) async {
        // 等待一段時間讓 JS 執行完成 (或 Cloudflare 5秒盾結束)
        await Future.delayed(const Duration(seconds: 3));
        
        final cookies = await _webviewCookieManager.getCookies(url: url!);
        if (cookies.isNotEmpty) {
          // 同步到 Dio NetworkService
          for (var cookie in cookies) {
            await NetworkService().cookieJar.saveFromResponse(
              Uri.parse(url.toString()), 
              [io.Cookie.fromSetCookieValue(cookie.toString())]
            );
          }
          completer.complete(true);
        } else {
          completer.complete(false);
        }
      },
    );

    await _headlessWebView?.run();
    return completer.future.timeout(const Duration(seconds: 15), onTimeout: () => false);
  }

  Future<void> dispose() async {
    await _headlessWebView?.dispose();
  }
}


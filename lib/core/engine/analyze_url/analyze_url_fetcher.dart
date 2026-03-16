import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'analyze_url_base.dart';
import 'analyze_url_utils.dart';
import 'package:legado_reader/core/models/base_source.dart';
import 'package:legado_reader/core/services/http_client.dart';
import 'package:legado_reader/core/services/backstage_webview.dart';
import 'package:legado_reader/core/services/rate_limiter.dart';

/// AnalyzeUrl 的請求執行邏輯擴展
extension AnalyzeUrlFetcher on AnalyzeUrlBase {
  Future<Uint8List?> getByteArray({CancelToken? cancelToken}) async {
    if (url.startsWith('data:')) {
      final commaIndex = url.indexOf(',');
      return commaIndex != -1 ? base64Decode(url.substring(commaIndex + 1)) : null;
    }

    final dio = HttpClient().client;
    final limiter = ConcurrentRateLimiter(source is BaseSource ? source : null);

    return await limiter.withLimit(() async {
      await setCookie();
      try {
        final requestUrl = encodedQuery != null ? '$url?$encodedQuery' : url;
        final options = Options(method: method, headers: headerMap.cast<String, dynamic>(), responseType: ResponseType.bytes, followRedirects: true);
        final response = method == 'POST' 
            ? await dio.request(requestUrl, data: encodedForm ?? body, options: options, cancelToken: cancelToken)
            : await dio.request(requestUrl, options: options, cancelToken: cancelToken);
        lastResponse = response;
        if (response.realUri.toString() != requestUrl) setRedirectUrl(response.realUri.toString());
        return Uint8List.fromList(response.data as List<int>);
      } catch (e) { rethrow; }
    });
  }

  Future<String> getResponseBody({CancelToken? cancelToken}) async {
    if (useWebView) {
      final webView = BackstageWebView(url: encodedQuery != null ? '$url?$encodedQuery' : url, headerMap: headerMap.cast<String, String>(), javaScript: webJs, delayTime: webViewDelayTime);
      final wvResponse = await webView.getStrResponse();
      return wvResponse['body']?.toString() ?? '';
    }

    final bytes = await getByteArray(cancelToken: cancelToken);
    if (bytes == null) return '';

    var charset = this.charset ?? 'UTF-8';
    final contentType = lastResponse?.headers.value('content-type')?.toLowerCase();
    if (contentType != null) {
      if (this.charset == null) {
        final match = RegExp(r'charset=([\w-]+)').firstMatch(contentType);
        if (match != null) charset = match.group(1)!;
      }
    }

    if (charset.toUpperCase().contains('GBK') || charset.toUpperCase().contains('GB2312') || charset.toUpperCase().contains('GB18030')) {
      return gbk.decode(bytes);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  void setRedirectUrl(String redirectUrl) {
    url = redirectUrl;
    final uri = Uri.parse(url);
    baseUrl = '${uri.scheme}://${uri.host}';
  }
}


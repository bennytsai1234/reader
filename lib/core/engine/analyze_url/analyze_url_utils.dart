import 'analyze_url_base.dart';
import 'package:legado_reader/core/services/cookie_store.dart';

/// AnalyzeUrl 的工具與輔助邏輯擴展
extension AnalyzeUrlUtils on AnalyzeUrlBase {
  void analyzeFields(String fieldsTxt) {
    encodedForm = encodeParams(fieldsTxt, charset, false);
  }

  void analyzeQuery(String query) {
    encodedQuery = encodeParams(query, charset, true);
  }

  String encodeParams(String params, String? charset, bool isQuery) {
    final parts = params.split('&');
    final sb = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) sb.write('&');
      final part = parts[i];
      final eqIndex = part.indexOf('=');
      if (eqIndex != -1) {
        sb.write(Uri.encodeQueryComponent(part.substring(0, eqIndex)));
        sb.write('=');
        sb.write(Uri.encodeQueryComponent(part.substring(eqIndex + 1)));
      } else {
        sb.write(Uri.encodeQueryComponent(part));
      }
    }
    return sb.toString();
  }

  String replaceInString(String str) {
    var result = str;
    if (key != null) result = result.replaceAll('{{key}}', key!);
    if (page != null) result = result.replaceAll('{{page}}', page.toString());
    if (speakText != null) result = result.replaceAll('{{speakText}}', Uri.encodeComponent(speakText!));
    if (speakSpeed != null) result = result.replaceAll('{{speakSpeed}}', speakSpeed.toString());
    if (voiceName != null) result = result.replaceAll('{{voiceName}}', voiceName!);
    return result;
  }

  Future<void> setCookie() async {
    final domain = CookieStore().getSubDomain(url);
    final cookie = await CookieStore().getCookie(domain);
    if (cookie.isNotEmpty) {
      final headerCookie = headerMap['Cookie']?.toString() ?? '';
      if (headerCookie.isNotEmpty) {
        headerMap['Cookie'] = CookieStore().mapToCookie({
          ...CookieStore().cookieToMap(cookie),
          ...CookieStore().cookieToMap(headerCookie),
        });
      } else {
        headerMap['Cookie'] = cookie;
      }
    }
  }
}


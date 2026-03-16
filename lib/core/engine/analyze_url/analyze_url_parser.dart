import 'dart:convert';
import 'analyze_url_base.dart';
import '../rule_analyzer.dart';
import 'analyze_url_utils.dart';

/// AnalyzeUrl 的規則解析邏輯擴展
extension AnalyzeUrlParser on AnalyzeUrlBase {
  void initUrl() {
    ruleUrl = rawUrl;
    analyzeJs();
    replaceKeyPageJs();
    analyzeUrlLogic();
  }

  void analyzeJs() {
    var start = 0;
    final matches = AnalyzeUrlBase.jsPattern.allMatches(ruleUrl);
    var result = ruleUrl;
    for (final match in matches) {
      if (match.start > start) {
        final prefix = ruleUrl.substring(start, match.start).trim();
        if (prefix.isNotEmpty) result = prefix.replaceAll('@result', result);
      }
      String jsCode;
      if (match.group(0)!.toLowerCase() == '@js:') {
        jsCode = ruleUrl.substring(match.end).trim();
        result = analyzer?.evalJS(jsCode, result)?.toString() ?? result;
        ruleUrl = result;
        return;
      } else {
        jsCode = match.group(2)!.trim();
        result = analyzer?.evalJS(jsCode, result)?.toString() ?? result;
      }
      start = match.end;
    }
    if (ruleUrl.length > start) {
      final suffix = ruleUrl.substring(start).trim();
      if (suffix.isNotEmpty) result = suffix.replaceAll('@result', result);
    }
    ruleUrl = result;
  }

  void replaceKeyPageJs() {
    var result = ruleUrl;
    if (result.contains('{{') && result.contains('}}') && analyzer != null) {
      final ra = RuleAnalyzer(result);
      result = ra.innerRuleRange('{{', '}}', fr: (js) => analyzer!.evalJS(js, null)?.toString() ?? '');
    }
    if (key != null) result = result.replaceAll('{{key}}', key!);
    if (page != null) {
      result = result.replaceAll('{{page}}', page.toString());
      result = result.replaceAllMapped(AnalyzeUrlBase.pagePattern, (match) {
        final pages = match.group(1)!.split(',');
        return page! <= pages.length ? pages[page! - 1].trim() : pages.last.trim();
      });
    }
    ruleUrl = result;
  }

  void analyzeUrlLogic() {
    final match = AnalyzeUrlBase.paramPattern.firstMatch(ruleUrl);
    String urlNoOption;
    if (match != null) {
      urlNoOption = ruleUrl.substring(0, match.start).trim();
      final optionStr = ruleUrl.substring(match.end).trim();
      try {
        final options = jsonDecode(optionStr) as Map<String, dynamic>;
        if (options.containsKey('method')) method = options['method'].toString().toUpperCase();
        if (options.containsKey('headers')) {
          (options['headers'] as Map<String, dynamic>).forEach((k, v) {
            if (k == 'proxy') {
              proxy = v.toString();
            } else {
              headerMap[k] = v.toString();
            }
          });
        }
        if (options.containsKey('body')) {
          body = options['body'];
          if (body is String && analyzer != null) body = replaceInString(body as String);
        }
        if (options.containsKey('type')) type = options['type'].toString();
        if (options.containsKey('charset')) charset = options['charset'].toString();
        if (options.containsKey('retry')) retry = int.tryParse(options['retry'].toString()) ?? 0;
        if (options.containsKey('webView')) {
          final wv = options['webView'];
          useWebView = wv == true || wv == 'true';
        }
        if (options.containsKey('webJs')) webJs = options['webJs'].toString();
        if (options.containsKey('webViewDelayTime')) webViewDelayTime = int.tryParse(options['webViewDelayTime'].toString()) ?? 0;
        if (options.containsKey('js')) {
          final jsResult = analyzer?.evalJS(options['js'].toString(), urlNoOption);
          if (jsResult != null) urlNoOption = jsResult.toString();
        }
      } catch (_) {}
    } else {
      urlNoOption = ruleUrl.trim();
    }

    if (baseUrl != null && !urlNoOption.startsWith('http')) {
      url = Uri.parse(baseUrl!).resolve(urlNoOption).toString();
    } else {
      url = urlNoOption;
    }

    if (method == 'GET') {
      final pos = url.indexOf('?');
      if (pos != -1) {
        analyzeQuery(url.substring(pos + 1));
        url = '${url.substring(0, pos)}?$encodedQuery';
        encodedQuery = null;
      }
    } else if (method == 'POST') {
      if (body != null && body is String) {
        final bodyStr = body as String;
        if (!bodyStr.trim().startsWith('{') && !bodyStr.trim().startsWith('[') && !bodyStr.trim().startsWith('<') && headerMap['Content-Type'] == null) {
          analyzeFields(bodyStr);
        }
      }
    }
  }
}


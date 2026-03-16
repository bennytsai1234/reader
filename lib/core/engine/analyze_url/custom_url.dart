import 'dart:convert';
import 'analyze_url_base.dart';

/// CustomUrl - 自定義 URL 封裝
/// 用於解析與構建帶有 JSON 屬性的 URL (如 url,{"headers":{...}})
/// (原 Android model/analyzeRule/CustomUrl.kt)
class CustomUrl {
  late String _url;
  final Map<String, dynamic> _attribute = {};

  CustomUrl(String urlStr) {
    final match = AnalyzeUrlBase.paramPattern.firstMatch(urlStr);
    if (match != null) {
      _url = urlStr.substring(0, match.start).trim();
      final attrStr = urlStr.substring(match.end).trim();
      try {
        final Map<String, dynamic> map = jsonDecode(attrStr);
        _attribute.addAll(map);
      } catch (_) {}
    } else {
      _url = urlStr.trim();
    }
  }

  CustomUrl putAttribute(String key, dynamic value) {
    if (value == null) {
      _attribute.remove(key);
    } else {
      _attribute[key] = value;
    }
    return this;
  }

  String getUrl() => _url;
  Map<String, dynamic> getAttr() => _attribute;

  @override
  String toString() {
    if (_attribute.isEmpty) return _url;
    return '$_url,${jsonEncode(_attribute)}';
  }
}
// AI_PORT: GAP-ANALYZE-01 derived from CustomUrl.kt


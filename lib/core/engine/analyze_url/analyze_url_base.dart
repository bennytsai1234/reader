import 'package:dio/dio.dart';
import '../analyze_rule.dart';

/// AnalyzeUrl 的基礎屬性與初始化定義
abstract class AnalyzeUrlBase {
  static final RegExp jsPattern = RegExp(r'@js:|(<js>([\w\W]*?)</js>)', caseSensitive: false);
  static final RegExp pagePattern = RegExp(r'<(.*?)>');
  static final RegExp paramPattern = RegExp(r'\s*,\s*(?=\{)');

  final String rawUrl;
  final String? key;
  final int? page;
  final String? speakText;
  final int? speakSpeed;
  final String? voiceName;
  String? baseUrl;
  final AnalyzeRule? analyzer;
  final dynamic source;

  String ruleUrl = '';
  String url = '';
  String method = 'GET';
  Map<String, dynamic> headerMap = {};
  dynamic body;
  String? charset;
  String? type;
  String? proxy;
  int retry = 0;
  bool useWebView = false;
  String? webJs;
  int webViewDelayTime = 0;
  String? encodedQuery;
  String? encodedForm;
  Response? lastResponse;

  AnalyzeUrlBase(this.rawUrl, {this.key, this.page, this.speakText, this.speakSpeed, this.voiceName, this.baseUrl, this.analyzer, this.source, Map<String, dynamic>? initialHeaders}) {
    if (initialHeaders != null) headerMap.addAll(initialHeaders);
    if (baseUrl != null && !baseUrl!.startsWith('http')) baseUrl = 'http://$baseUrl';
  }
}


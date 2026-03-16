import 'package:flutter_js/flutter_js.dart';
import 'package:legado_reader/core/models/base_source.dart';
import 'package:legado_reader/core/services/cookie_store.dart';
import 'package:legado_reader/core/services/cache_manager.dart';
import 'query_ttf.dart';

/// JsExtensions 的基礎狀態與共用緩存
abstract class JsExtensionsBase {
  final JavascriptRuntime runtime;
  final BaseSource? source;
  final CookieStore cookieStore = CookieStore();
  final CacheManager cacheManager = CacheManager();
  
  static final Map<String, QueryTTF> ttfCache = {};
  static final Map<String, String> fontReplaceCache = {};
  
  // 全域 JS 作用域 (原 Android SharedJsScope)
  static final Map<String, dynamic> sharedScope = {};

  JsExtensionsBase(this.runtime, {this.source});
}


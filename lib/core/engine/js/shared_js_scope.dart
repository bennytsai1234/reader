import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'js_engine.dart';
import 'package:legado_reader/core/services/cache_manager.dart';
import 'package:legado_reader/core/services/http_client.dart';

/// SharedJsScope - 跨腳本變數共用
/// (原 Android model/SharedJsScope.kt)
class SharedJsScope {
  // Simple LRU cache implementation using LinkedHashMap (preserves insertion order)
  static final LinkedHashMap<String, JsEngine> _scopeMap =
      LinkedHashMap<String, JsEngine>();
  static const int _maxCacheSize = 16;

  /// Generate MD5 hash for a string
  static String _md5Encode(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  /// Get or create a shared Javascript execution scope (JsEngine)
  static Future<JsEngine?> getScope(String? jsLib) async {
    if (jsLib == null || jsLib.trim().isEmpty) {
      return null;
    }

    final key = _md5Encode(jsLib);
    if (_scopeMap.containsKey(key)) {
      // LRU logic: move accessed item to the end
      final engine = _scopeMap.remove(key)!;
      _scopeMap[key] = engine;
      return engine;
    }

    final engine = JsEngine();

    // Check if jsLib is a JSON object
    final isJsonStr = jsLib.trim().startsWith('{') && jsLib.trim().endsWith('}');
    if (isJsonStr) {
      try {
        final jsMap = jsonDecode(jsLib) as Map<String, dynamic>;
        for (final value in jsMap.values) {
          final valStr = value.toString();
          if (valStr.startsWith('http')) {
            final fileName = _md5Encode(valStr);
            var jsContent = await CacheManager().get(fileName);
            if (jsContent == null) {
              try {
                final response = await HttpClient().client.get(valStr);
                jsContent = response.data.toString();
                await CacheManager().put(fileName, jsContent);
              } catch (e) {
                throw Exception('下載jsLib-$valStr失敗: $e');
              }
            }
            engine.evaluate(jsContent);
          }
        }
      } catch (e) {
        // Fallback to evaluating it as normal script if JSON parsing fails
        engine.evaluate(jsLib);
      }
    } else {
      engine.evaluate(jsLib);
    }

    // Add to cache
    _scopeMap[key] = engine;
    if (_scopeMap.length > _maxCacheSize) {
      final firstKey = _scopeMap.keys.first;
      final oldEngine = _scopeMap.remove(firstKey);
      oldEngine?.dispose();
    }

    return engine;
  }

  /// Remove a scope from the cache
  static void remove(String? jsLib) {
    if (jsLib == null || jsLib.trim().isEmpty) return;

    final key = _md5Encode(jsLib);
    final engine = _scopeMap.remove(key);
    engine?.dispose();
  }
}


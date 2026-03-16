import 'package:flutter/foundation.dart';
import 'js_extensions_base.dart';
import 'extensions/js_network_extensions.dart';
import 'extensions/js_crypto_extensions.dart';
import 'extensions/js_string_extensions.dart';
import 'extensions/js_file_extensions.dart';
import 'extensions/js_font_extensions.dart';
import 'extensions/js_java_object.dart';
import 'js_encode_utils.dart';
import 'package:legado_reader/core/services/http_client.dart';

export 'js_extensions_base.dart';
export 'extensions/js_network_extensions.dart';
export 'extensions/js_crypto_extensions.dart';
export 'extensions/js_string_extensions.dart';
export 'extensions/js_file_extensions.dart';
export 'extensions/js_font_extensions.dart';

/// JsExtensions - JS 橋接總控 (重構後)
/// (原 Android help/JsExtensions.kt)
class JsExtensions extends JsExtensionsBase {
  JsExtensions(super.runtime, {super.source});

  void inject() {
    _injectCoreHandlers();
    injectNetworkExtensions();
    injectCryptoExtensions();
    injectStringExtensions();
    injectFileExtensions();
    injectFontExtensions();
    injectJavaObjectJs();
  }

  void _injectCoreHandlers() {
    runtime.onMessage('put', (args) { if (args is List && args.length >= 2) JsExtensionsBase.sharedScope[args[0].toString()] = args[1]; });
    runtime.onMessage('get', (args) => JsExtensionsBase.sharedScope[args.toString()]);
    runtime.onMessage('log', (args) => debugPrint('JS_LOG: $args'));
    runtime.onMessage('toast', (args) => debugPrint('JS_TOAST: $args'));
    runtime.onMessage('cacheFile', (args) => cacheFile(args[0].toString(), args.length > 1 ? args[1] as int : 0));
  }

  Future<String> cacheFile(String url, int saveTime) async {
    final key = JsEncodeUtils.md5Encode16(url);
    final cached = await cacheManager.get(key);
    if (cached != null) return cached;
    try {
      final response = await HttpClient().client.get(url);
      final content = response.data.toString();
      if (content.isNotEmpty) await cacheManager.put(key, content);
      return content;
    } catch (_) { return ''; }
  }
}


import 'package:url_launcher/url_launcher.dart';

/// NavigationArgsCache - 導航與大數據傳遞快取 (原 Android help/IntentData.kt)
/// 負責跨頁面傳遞無法透過 URL 參數傳遞的大型物件
class NavigationArgsCache {
  static final NavigationArgsCache _instance = NavigationArgsCache._internal();
  factory NavigationArgsCache() => _instance;
  NavigationArgsCache._internal();

  final Map<String, dynamic> _bigData = {};

  String put(dynamic data, {String? key}) {
    if (data == null) return '';
    final k = key ?? DateTime.now().millisecondsSinceEpoch.toString();
    _bigData[k] = data;
    return k;
  }

  T? get<T>(String? key) {
    if (key == null) return null;
    final data = _bigData[key];
    _bigData.remove(key);
    return data as T?;
  }
}

/// SystemLauncher - 系統跳轉與外部鏈接助手 (原 Android help/IntentHelp.kt)
class SystemLauncher {
  /// 開啟外部瀏覽器
  static Future<void> openBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 打開語音設定 (iOS 跳轉到 Accessibility)
  static Future<void> openSpeechSetting() async {
    // Note: App-Prefs is unofficial Apple URL scheme, might not work in all iOS versions.
    // Fallback to general settings if needed.
    final uri = Uri.parse('App-Prefs:root=ACCESSIBILITY&path=SPEECH');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final settingsUri = Uri.parse('app-settings:');
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri);
      }
    }
  }
}


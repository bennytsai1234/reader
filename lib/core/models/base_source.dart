/// BaseSource - 資源來源基礎介面
/// (原 Android data/entities/BaseSource.kt)
abstract class BaseSource {
  String? get jsLib;
  bool? get enabledCookieJar;
  String? get concurrentRate;
  String? get header;
  String? get loginUrl;
  String? get loginUi;

  String getTag();
  String getKey();
}


import 'package:inkpage_reader/core/base/base_provider.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/engine/analyze_url.dart';
import 'package:inkpage_reader/core/services/cookie_store.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'browser_params.dart';

class BrowserProvider extends BaseProvider {
  final BrowserParams params;

  String? _baseUrl;
  Map<String, String> _headerMap = {};
  String? _html;
  bool _isInitialized = false;

  String? get baseUrl => _baseUrl;
  Map<String, String> get headerMap => _headerMap;
  String? get html => _html;
  bool get isInitialized => _isInitialized;

  BrowserProvider(this.params);

  Future<void> init() async {
    if (_isInitialized) return;

    await runTask(() async {
      final source =
          params.sourceOrigin != null
              ? await getIt<BookSourceDao>().getByUrl(params.sourceOrigin!)
              : null;

      final analyzeUrl = await AnalyzeUrl.create(params.url, source: source);

      _baseUrl = analyzeUrl.url;
      _headerMap = analyzeUrl.headerMap.cast<String, String>();

      // 同步 Cookie 到 WebView (如果有的話)
      final domain = CookieStore().getSubDomain(_baseUrl!);
      final cookie = await CookieStore().getCookie(domain);
      if (cookie.isNotEmpty) {
        _headerMap['Cookie'] = cookie;
      }

      if (analyzeUrl.method == 'POST') {
        _html = await analyzeUrl.getResponseBody();
      }

      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<String?> saveVerificationResult(
    String currentHtml, {
    String? currentUrl,
    String? cookie,
  }) async {
    if (!params.sourceVerificationEnable) return null;

    final effectiveUrl =
        currentUrl?.isNotEmpty == true ? currentUrl! : (_baseUrl ?? params.url);

    return await runTask(() async {
      final normalizedCookie = cookie?.trim();
      if (normalizedCookie != null && normalizedCookie.isNotEmpty) {
        await CookieStore().replaceCookie(effectiveUrl, normalizedCookie);
      }

      if (params.refetchAfterSuccess) {
        final source =
            params.sourceOrigin != null
                ? await getIt<BookSourceDao>().getByUrl(params.sourceOrigin!)
                : null;
        final analyzeUrl = await AnalyzeUrl.create(params.url, source: source);
        return await analyzeUrl.getResponseBody();
      }

      return currentHtml;
    });
  }

  Future<void> disableSource() async {
    if (params.sourceOrigin == null) return;
    await runTask(() async {
      final source = await getIt<BookSourceDao>().getByUrl(
        params.sourceOrigin!,
      );
      if (source != null) {
        source.enabled = false;
        await getIt<BookSourceDao>().upsert(source);
      }
    });
  }

  Future<void> deleteSource() async {
    if (params.sourceOrigin == null) return;
    await runTask(() async {
      await getIt<BookSourceDao>().deleteByUrl(params.sourceOrigin!);
    });
  }
}

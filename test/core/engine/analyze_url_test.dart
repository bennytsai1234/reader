import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/analyze_url.dart';
import '../../test_helper.dart';

void main() {
  setupTestDI();

  group('AnalyzeUrl Tests', () {
    test('Basic URL variable substitution', () {
      final analyzer = AnalyzeUrl(
        'https://example.com/search?q={{key}}&p={{page}}',
        key: 'novel',
        page: 2,
      );
      expect(analyzer.url, 'https://example.com/search?q=novel&p=2');
    });

    test('Page list substitution <p1,p2,p3>', () {
      final analyzer1 = AnalyzeUrl('https://example.com/list/<1,2,3>.html', page: 1);
      expect(analyzer1.url, 'https://example.com/list/1.html');

      final analyzer2 = AnalyzeUrl('https://example.com/list/<1,2,3>.html', page: 3);
      expect(analyzer2.url, 'https://example.com/list/3.html');

      final analyzer3 = AnalyzeUrl('https://example.com/list/<1,2,3>.html', page: 5);
      expect(analyzer3.url, 'https://example.com/list/3.html');
    });

    test('Legado options parsing', () {
      const rawUrl = 'https://example.com/api, {"method":"POST", "body": "q={{key}}", "headers": {"X-Test": "Value"}}';
      final analyzer = AnalyzeUrl(rawUrl, key: 'novel');
      
      expect(analyzer.url, 'https://example.com/api');
      expect(analyzer.method, 'POST');
      expect(analyzer.body, 'q=novel');
      expect(analyzer.headerMap['X-Test'], 'Value');
    });

    test('Relative URL resolution', () {
      final analyzer = AnalyzeUrl('search.php?q={{key}}', key: 'novel', baseUrl: 'https://example.com/path/');
      expect(analyzer.url, 'https://example.com/path/search.php?q=novel');
    });

    test('WebView flag detection', () {
      final analyzer = AnalyzeUrl('https://example.com, {"webView": true}');
      expect(analyzer.useWebView, true);
    });
  });
}

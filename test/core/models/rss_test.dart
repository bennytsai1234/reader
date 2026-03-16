import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/models/rss_article.dart';
import 'package:legado_reader/core/models/rss_star.dart';
import 'package:legado_reader/core/models/rss_read_record.dart';

void main() {
  group('RSS Models Tests', () {
    test('RssSource toJson/fromJson', () {
      final source = RssSource(
        sourceUrl: 'https://example.com/rss',
        sourceName: 'Test RSS',
        enabled: true,
      );
      final json = source.toJson();
      final fromJson = RssSource.fromJson(json);
      expect(fromJson.sourceUrl, source.sourceUrl);
      expect(fromJson.sourceName, source.sourceName);
    });

    test('RssArticle variableMap and putVariable', () {
      final article = RssArticle(
        origin: 'source1',
        link: 'https://example.com/a1',
        variable: '{"key1": "val1"}',
      );
      expect(article.variableMap['key1'], 'val1');
      expect(article.getVariable('key1'), 'val1');

      article.putVariable('key2', 'val2');
      expect(article.variableMap['key2'], 'val2');
      expect(article.variable!.contains('key2'), true);
    });

    test('RssStar conversion', () {
      final star = RssStar(
        origin: 'source1',
        title: 'Star Title',
        link: 'https://example.com/star1',
      );
      final json = star.toJson();
      final fromJson = RssStar.fromJson(json);
      expect(fromJson.title, 'Star Title');
    });

    test('RssReadRecord serialization', () {
      final record = RssReadRecord(
        record: 'record_key',
        title: 'Read Title',
        read: true,
      );
      final json = record.toJson();
      final fromJson = RssReadRecord.fromJson(json);
      expect(fromJson.record, 'record_key');
      expect(fromJson.read, true);
    });
  });
}

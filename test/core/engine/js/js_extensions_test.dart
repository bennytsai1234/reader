import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/engine/js/js_extensions.dart';
import 'package:inkpage_reader/core/models/book_source.dart';

import '../../../test_helper.dart';

void main() {
  setupTestDI();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsExtensions bridge completeness', () {
    JavascriptRuntime? runtime;
    Object? runtimeError;

    setUp(() {
      runtimeError = null;
      try {
        runtime = getJavascriptRuntime();
      } catch (error) {
        runtime = null;
        runtimeError = error;
      }
    });

    tearDown(() {
      runtime?.dispose();
    });

    test('java bridge exposes missing helper methods', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      expect(
        runtime!.evaluate('typeof java.base64Decode').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.md5Encode16').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.hexEncodeToString').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.hexDecodeToString').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.randomUUID').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.timeFormat').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.timeFormatUTC').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof java.toNumChapter').stringResult,
        'function',
      );
    });

    test('java.log returns the original value like Legado', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        var logged = java.log("bridge-value");
        logged;
      ''');

      expect(result.stringResult, 'bridge-value');
    });

    test('cookie and cache bridges are exposed', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      expect(runtime!.evaluate('typeof cookie.set').stringResult, 'function');
      expect(
        runtime!.evaluate('typeof cookie.remove').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof cookie.getCookie').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof cookie.setCookie').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof cookie.removeCookie').stringResult,
        'function',
      );
      expect(runtime!.evaluate('typeof cache.get').stringResult, 'function');
      expect(
        runtime!.evaluate('typeof cache.getFile').stringResult,
        'function',
      );
      expect(runtime!.evaluate('typeof cache.put').stringResult, 'function');
      expect(
        runtime!.evaluate('typeof cache.putFile').stringResult,
        'function',
      );
    });

    test('source bridge is exposed when source exists', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(
        runtime!,
        source: BookSource(
          bookSourceUrl: 'https://example.com',
          bookSourceName: 'Example',
        ),
      );
      ext.inject();

      expect(
        runtime!.evaluate('typeof source.getLoginInfo').stringResult,
        'function',
      );
      expect(runtime!.evaluate('typeof source.getKey').stringResult, 'function');
      expect(
        runtime!.evaluate('typeof source.getVariable').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof source.setVariable').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof source.getHeaderMap').stringResult,
        'function',
      );
      expect(
        runtime!.evaluate('typeof source.putLoginInfo').stringResult,
        'function',
      );
      expect(runtime!.evaluate('typeof source.put').stringResult, 'function');
      expect(runtime!.evaluate('typeof source.get').stringResult, 'function');
    });

    test('Jsoup shim supports importClass and select text helpers', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        importClass(org.jsoup.Jsoup);
        var doc = Jsoup.parse('<div class="introduce">简介</div><div class="text-row">标签1</div><div class="text-row">标签2</div>');
        doc.select('.introduce').text() + '|' + doc.select('.text-row:eq(0)').text();
      ''');

      expect(result.stringResult, '简介|标签1');
    });

    test('Jsoup shim supports select().first().attr()', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        importClass(org.jsoup.Jsoup);
        var doc = Jsoup.parse('<div><a href="/chapter/1">第一章</a><a href="/chapter/2">第二章</a></div>');
        doc.select('a').first().attr('href');
      ''');

      expect(result.stringResult, '/chapter/1');
    });

    test('Jsoup shim supports data() and remove() mutations', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        importClass(org.jsoup.Jsoup);
        var doc = Jsoup.parse('<style>.hide:nth-last-child(2){display:none}</style><div class="hide">X</div><div class="show">Y</div>');
        var selector = String(doc.select("style").first().data()).replace(/{display:none}/g, ",").slice(0, -1);
        doc.select(selector).remove();
        doc.html();
      ''');

      expect(result.stringResult.contains('>X<'), isFalse);
      expect(result.stringResult.contains('>Y<'), isTrue);
    });

    test('Jsoup shim preserves middle nodes for nth-child removals', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        importClass(org.jsoup.Jsoup);
        var doc = Jsoup.parse('<style>.list>li:nth-child(1){display:none}.list>li:nth-last-child(1){display:none}</style><ul class="list"><li>A</li><li>B</li><li>C</li></ul>');
        var selector = String(doc.select("style").first().data()).replace(/{display:none}/g, ",").slice(0, -1);
        doc.select(selector).remove();
        doc.html();
      ''');

      expect(result.stringResult.contains('>A<'), isFalse);
      expect(result.stringResult.contains('>B<'), isTrue);
      expect(result.stringResult.contains('>C<'), isFalse);
    });

    test('JavaImporter shim supports Base64 and GZIP decode loops', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();
      final payload = base64Encode(gzip.encode(utf8.encode('解压成功')));

      final result = runtime!.evaluate('''
        var payload = "$payload";
        var javaImport = new JavaImporter();
        javaImport.importPackage(
          Packages.java.lang,
          Packages.java.io,
          Packages.java.util,
          Packages.java.util.zip
        );
        with(javaImport) {
          function decode(content) {
            var decoded = Base64.getDecoder().decode(String(content));
            var output = new ByteArrayOutputStream();
            var input = new ByteArrayInputStream(decoded);
            var gzipInput = new GZIPInputStream(input);
            var buffer = String(" ").getBytes();
            while (true) {
              var read = gzipInput.read(buffer);
              if (read > 0) {
                output.write(buffer, 0, read);
              } else {
                return output.toString();
              }
            }
          }
          decode(payload);
        }
      ''');

      expect(result.stringResult, '解压成功');
    });

    test('Java String getBytes returns a writable buffer', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        var javaImport = new JavaImporter();
        javaImport.importPackage(Packages.java.lang);
        with(javaImport) {
          String(" ").getBytes().length;
        }
      ''');

      expect(result.stringResult, '1');
    });

    test(
      'java.gzipToString accepts byte arrays from base64DecodeToByteArray',
      () {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }
        final ext = JsExtensions(runtime!);
        ext.inject();
        final payload = base64Encode(gzip.encode(utf8.encode('解压成功')));

        final result = runtime!.evaluate('''
        var payload = "$payload";
        java.gzipToString(java.base64DecodeToByteArray(payload), "UTF-8");
      ''');

        expect(result.stringResult, '解压成功');
      },
    );

    test(
      'java.aesBase64DecodeToString helper matches symmetric crypto output',
      () {
        if (runtime == null) {
          expect(runtimeError, isNotNull);
          return;
        }
        final ext = JsExtensions(runtime!);
        ext.inject();

        final result = runtime!.evaluate(r'''
        var key = "1234567890123456";
        var iv = "6543210987654321";
        var crypto = java.createSymmetricCrypto("AES/CBC/PKCS5Padding", key, iv);
        var encoded = crypto.encryptBase64("hello");
        java.aesBase64DecodeToString(encoded, key, "AES/CBC/PKCS5Padding", iv);
      ''');

        expect(result.stringResult, 'hello');
      },
    );

    test('java.toNumChapter matches Legado chapter numbering helper', () {
      if (runtime == null) {
        expect(runtimeError, isNotNull);
        return;
      }
      final ext = JsExtensions(runtime!);
      ext.inject();

      final result = runtime!.evaluate(r'''
        java.toNumChapter("第十二章 归来");
      ''');

      expect(result.stringResult, '第12章 归来');
    });
  });
}

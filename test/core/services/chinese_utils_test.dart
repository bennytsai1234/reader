import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:legado_reader/core/services/chinese_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_open_chinese_convert');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'convert') {
        String? text;
        if (methodCall.arguments is Map) {
          text = methodCall.arguments['text'];
        } else if (methodCall.arguments is List) {
          text = methodCall.arguments[0];
        } else if (methodCall.arguments is String) {
          text = methodCall.arguments;
        }

        if (text == null) return '';

        // Simple mock implementation for testing
        if (text == '万与丑专业') return '萬與醜專業';
        if (text == '书买乱争') return '書買亂爭';
        if (text == '萬與醜專業') return '万与丑专业';
        if (text == '書買亂爭') return '书买乱争';
        return text;
      }
      return null;
    });
  });

  group('ChineseUtils Tests', () {
    test('Simplified to Traditional conversion', () async {
      expect(await ChineseUtils.s2t('万与丑专业'), '萬與醜專業');
      expect(await ChineseUtils.s2t('书买乱争'), '書買亂爭');
    });

    test('Traditional to Simplified conversion', () async {
      expect(await ChineseUtils.t2s('萬與醜專業'), '万与丑专业');
      expect(await ChineseUtils.t2s('書買亂爭'), '书买乱争');
    });

    test('Handling characters not in table', () async {
      expect(await ChineseUtils.s2t('你好 abc 123'), '你好 abc 123');
    });
  });
}

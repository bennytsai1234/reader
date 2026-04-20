import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/services/source_verification_service.dart';

void main() {
  group('SourceVerificationService', () {
    test('sendResult completes the matching request', () async {
      final service = SourceVerificationService();
      final future = service.getVerificationResult(
        sourceKey: 'source://demo',
        url: 'https://example.com/verify',
        title: '驗證',
        useBrowser: true,
      );

      final request = await service.requestStream.first;
      service.sendResult(request, '<html>ok</html>');

      await expectLater(future, completion('<html>ok</html>'));
    });

    test(
      'cancelRequest completes with VerificationCancelledException',
      () async {
        final service = SourceVerificationService();
        final future = service.getVerificationResult(
          sourceKey: 'source://demo',
          url: 'https://example.com/code.png',
          title: '輸入驗證碼',
          useBrowser: false,
        );

        final request = await service.requestStream.first;
        service.cancelRequest(request);

        await expectLater(
          future,
          throwsA(isA<VerificationCancelledException>()),
        );
      },
    );

    test('request times out when nobody handles it', () async {
      final service = SourceVerificationService();

      await expectLater(
        service.getVerificationResult(
          sourceKey: 'source://demo',
          url: 'https://example.com/timeout',
          title: '驗證超時',
          useBrowser: true,
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<VerificationTimedOutException>()),
      );
    });
  });
}

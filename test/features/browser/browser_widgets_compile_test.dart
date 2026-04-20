import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/services/source_verification_service.dart';
import 'package:inkpage_reader/features/browser/browser_page.dart';
import 'package:inkpage_reader/features/browser/browser_params.dart';
import 'package:inkpage_reader/features/browser/source_verification_coordinator.dart';
import 'package:inkpage_reader/features/browser/verification_code_dialog.dart';

void main() {
  test('browser verification widgets can be constructed', () {
    final request = VerificationRequest(
      id: 'verification_0',
      sourceKey: 'source://demo',
      url: 'https://example.com/verify',
      title: '驗證',
      useBrowser: true,
      timeout: const Duration(minutes: 1),
      createdAt: DateTime(2025),
      completer: Completer<String>(),
    );

    expect(
      () => BrowserPage(
        params: BrowserParams(
          url: request.url,
          title: request.title,
          sourceVerificationEnable: true,
          verificationRequest: request,
        ),
      ),
      returnsNormally,
    );
    expect(() => VerificationCodeDialog(request: request), returnsNormally);
    expect(
      () => SourceVerificationCoordinator(
        navigatorKey: GlobalKey<NavigatorState>(),
        child: const SizedBox.shrink(),
      ),
      returnsNormally,
    );
  });
}

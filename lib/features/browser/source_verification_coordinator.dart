import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/source_type.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/source_verification_service.dart';

import 'browser_page.dart';
import 'browser_params.dart';
import 'verification_code_dialog.dart';

class SourceVerificationCoordinator extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const SourceVerificationCoordinator({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<SourceVerificationCoordinator> createState() =>
      _SourceVerificationCoordinatorState();
}

class _SourceVerificationCoordinatorState
    extends State<SourceVerificationCoordinator> {
  final Queue<VerificationRequest> _pendingRequests =
      Queue<VerificationRequest>();
  StreamSubscription<VerificationRequest>? _requestSubscription;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestSubscription = SourceVerificationService().requestStream.listen(
      (request) {
        _pendingRequests.add(request);
        unawaited(_processQueue());
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLog.e(
          'Source verification stream error: $error',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<void> _processQueue() async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;

    try {
      while (mounted && _pendingRequests.isNotEmpty) {
        final request = _pendingRequests.removeFirst();
        if (!SourceVerificationService().isPending(request)) {
          continue;
        }

        final navigator = await _waitForNavigator();
        if (navigator == null) {
          SourceVerificationService().failRequest(
            request,
            const VerificationFailedException('驗證頁面尚未就緒'),
          );
          continue;
        }

        await _presentRequest(navigator, request);
      }
    } finally {
      _isProcessing = false;
      if (mounted && _pendingRequests.isNotEmpty) {
        unawaited(_processQueue());
      }
    }
  }

  Future<NavigatorState?> _waitForNavigator() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final navigator = widget.navigatorKey.currentState;
      if (navigator != null && widget.navigatorKey.currentContext != null) {
        return navigator;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return widget.navigatorKey.currentState;
  }

  Future<void> _presentRequest(
    NavigatorState navigator,
    VerificationRequest request,
  ) async {
    late final Route<void> route;

    if (request.useBrowser) {
      route = MaterialPageRoute<void>(
        settings: RouteSettings(name: 'source-verification:${request.id}'),
        builder:
            (_) => BrowserPage(
              params: BrowserParams(
                url: request.url,
                title: request.title,
                sourceOrigin: request.sourceKey,
                sourceType: SourceType.book,
                sourceVerificationEnable: true,
                verificationRequest: request,
              ),
            ),
      );
    } else {
      route = DialogRoute<void>(
        context: navigator.context,
        barrierDismissible: false,
        settings: RouteSettings(name: 'source-code-entry:${request.id}'),
        builder: (_) => VerificationCodeDialog(request: request),
      );
    }

    final closeOnFailure = request.completer.future.catchError((_) async {
      if (route.isActive) {
        navigator.removeRoute(route);
      }
      return '';
    });

    await navigator.push(route);
    await closeOnFailure.catchError((_) => '');

    if (SourceVerificationService().isPending(request)) {
      SourceVerificationService().cancelRequest(request);
    }
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

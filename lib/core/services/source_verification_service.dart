import 'dart:async';

abstract class VerificationException implements Exception {
  final String message;

  const VerificationException(this.message);

  @override
  String toString() => message;
}

class VerificationCancelledException extends VerificationException {
  const VerificationCancelledException([super.message = '驗證已取消']);
}

class VerificationTimedOutException extends VerificationException {
  const VerificationTimedOutException([super.message = '驗證超時，請重試']);
}

class VerificationFailedException extends VerificationException {
  const VerificationFailedException(super.message);
}

/// VerificationRequest - 驗證請求封裝
class VerificationRequest {
  final String id;
  final String sourceKey;
  final String url;
  final String title;
  final bool useBrowser;
  final Duration timeout;
  final DateTime createdAt;
  final Completer<String> completer;
  Timer? _timeoutTimer;

  VerificationRequest({
    required this.id,
    required this.sourceKey,
    required this.url,
    required this.title,
    required this.useBrowser,
    required this.timeout,
    required this.createdAt,
    required this.completer,
  });
}

/// SourceVerificationService - 書源驗證服務
/// (原 Android help/source/SourceVerificationHelp.kt)
class SourceVerificationService {
  static final SourceVerificationService _instance =
      SourceVerificationService._internal();
  factory SourceVerificationService() => _instance;

  final StreamController<VerificationRequest> _requestController =
      StreamController<VerificationRequest>.broadcast();
  final Map<String, VerificationRequest> _activeRequests =
      <String, VerificationRequest>{};
  int _requestCounter = 0;

  SourceVerificationService._internal();

  /// 請求流，UI 層應監聽此流以彈出驗證介面
  Stream<VerificationRequest> get requestStream => Stream.multi((controller) {
    final pendingRequests =
        _activeRequests.values
            .where((request) => !request.completer.isCompleted)
            .toList()
          ..sort((left, right) => left.createdAt.compareTo(right.createdAt));

    for (final request in pendingRequests) {
      controller.add(request);
    }

    final subscription = _requestController.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  }, isBroadcast: true);

  /// 獲取驗證結果 (原 Android getVerificationResult)
  Future<String> getVerificationResult({
    required String sourceKey,
    required String url,
    required String title,
    required bool useBrowser,
    Duration timeout = const Duration(minutes: 1),
  }) {
    final completer = Completer<String>();

    final request = VerificationRequest(
      id: 'verification_${_requestCounter++}',
      sourceKey: sourceKey,
      url: url,
      title: title,
      useBrowser: useBrowser,
      timeout: timeout,
      createdAt: DateTime.now(),
      completer: completer,
    );

    _activeRequests[request.id] = request;
    request._timeoutTimer = Timer(
      timeout,
      () => _completeError(request, const VerificationTimedOutException()),
    );
    _requestController.add(request);

    return completer.future.whenComplete(() {
      request._timeoutTimer?.cancel();
      _activeRequests.remove(request.id);
    });
  }

  /// UI 完成驗證後調用此方法回傳結果
  void sendResult(VerificationRequest request, String result) {
    _complete(request, result);
  }

  void cancelRequest(VerificationRequest request, [String message = '驗證已取消']) {
    _completeError(request, VerificationCancelledException(message));
  }

  void failRequest(VerificationRequest request, Object error) {
    _completeError(
      request,
      error is VerificationException
          ? error
          : VerificationFailedException(error.toString()),
    );
  }

  bool isPending(VerificationRequest request) {
    final activeRequest = _activeRequests[request.id];
    return activeRequest != null && !activeRequest.completer.isCompleted;
  }

  void _complete(VerificationRequest request, String result) {
    final activeRequest = _activeRequests[request.id];
    if (activeRequest == null || activeRequest.completer.isCompleted) {
      return;
    }
    activeRequest._timeoutTimer?.cancel();
    activeRequest.completer.complete(result);
  }

  void _completeError(VerificationRequest request, Object error) {
    final activeRequest = _activeRequests[request.id];
    if (activeRequest == null || activeRequest.completer.isCompleted) {
      return;
    }
    activeRequest._timeoutTimer?.cancel();
    activeRequest.completer.completeError(error);
  }
}

import 'dart:async';

/// VerificationRequest - 驗證請求封裝
class VerificationRequest {
  final String sourceKey;
  final String url;
  final String title;
  final bool useBrowser;
  final Completer<String> completer;

  VerificationRequest({
    required this.sourceKey,
    required this.url,
    required this.title,
    required this.useBrowser,
    required this.completer,
  });
}

/// SourceVerificationService - 書源驗證服務
/// (原 Android help/source/SourceVerificationHelp.kt)
class SourceVerificationService {
  static final SourceVerificationService _instance = SourceVerificationService._internal();
  factory SourceVerificationService() => _instance;

  final StreamController<VerificationRequest> _requestController = StreamController<VerificationRequest>.broadcast();

  SourceVerificationService._internal();

  /// 請求流，UI 層應監聽此流以彈出驗證介面
  Stream<VerificationRequest> get requestStream => _requestController.stream;

  /// 獲取驗證結果 (原 Android getVerificationResult)
  Future<String> getVerificationResult({
    required String sourceKey,
    required String url,
    required String title,
    required bool useBrowser,
  }) async {
    final completer = Completer<String>();
    
    final request = VerificationRequest(
      sourceKey: sourceKey,
      url: url,
      title: title,
      useBrowser: useBrowser,
      completer: completer,
    );

    _requestController.add(request);

    // 設定超時 (原 Android 1分鐘)
    return completer.future.timeout(
      const Duration(minutes: 1),
      onTimeout: () => throw TimeoutException('驗證超時，請重試'),
    );
  }

  /// UI 完成驗證後調用此方法回傳結果
  void sendResult(VerificationRequest request, String result) {
    if (!request.completer.isCompleted) {
      request.completer.complete(result);
    }
  }
}


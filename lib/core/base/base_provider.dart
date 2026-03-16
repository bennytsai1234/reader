import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// BaseProvider - 所有 Provider 的基類
/// 規範 Loading 狀態與錯誤處理流程
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  final CancelToken _cancelToken = CancelToken();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CancelToken get cancelToken => _cancelToken;

  /// 設定 Loading 狀態
  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// 設定錯誤訊息
  void setError(String? value) {
    if (_errorMessage != value) {
      _errorMessage = value;
      notifyListeners();
    }
  }

  /// 執行異步任務，自動處理 Loading 與 Error
  Future<T?> runTask<T>(
    Future<T> Function() task, {
    bool showLoading = true,
    bool handleError = true,
  }) async {
    if (showLoading) setLoading(true);
    if (handleError) setError(null);

    try {
      final result = await task();
      return result;
    } catch (e, stack) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('Task cancelled: ${e.message}');
        return null;
      }
      debugPrint('Provider Error: $e\n$stack');
      if (handleError) {
        setError(e.toString());
      }
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel('Provider disposed');
    super.dispose();
  }
}


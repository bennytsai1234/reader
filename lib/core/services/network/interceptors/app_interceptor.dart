import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../../di/injection.dart';

/// AppInterceptor - 全域網路攔截器
/// 負責處理：日誌記錄、自定義 Header、錯誤狀態碼處理
class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    getIt<Logger>().d('Network Request: [${options.method}] ${options.uri}');
    // 這裡可以動態加入特定的 Header，例如：
    // options.headers['App-Version'] = '1.0.0';
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    getIt<Logger>().d('Network Response: [${response.statusCode}] ${response.requestOptions.uri}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final errorMessage = _getErrorMessage(err);
    getIt<Logger>().e('Network Error: $errorMessage', error: err, stackTrace: err.stackTrace);
    
    // 這裡可以將原始錯誤封裝後再拋出，或者進行重試邏輯
    super.onError(err, handler);
  }

  String _getErrorMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return '連線逾時，請檢查網路狀態';
      case DioExceptionType.sendTimeout:
        return '發送請求逾時';
      case DioExceptionType.receiveTimeout:
        return '伺服器響應逾時';
      case DioExceptionType.badResponse:
        return '伺服器回應異常: ${err.response?.statusCode}';
      case DioExceptionType.cancel:
        return '請求已取消';
      case DioExceptionType.connectionError:
        return '無法連線至伺服器';
      default:
        return '未知的網路錯誤';
    }
  }
}


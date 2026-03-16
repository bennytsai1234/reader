import 'dart:convert';

/// ApiResponse - (原 Android ReturnData.kt)
/// 負責 Web 服務的 API 回傳格式封裝
class ApiResponse {
  final bool isSuccess;
  final String errorMsg;
  final dynamic data;

  ApiResponse({
    this.isSuccess = false,
    this.errorMsg = '未知錯誤,請聯繫開發者!',
    this.data,
  });

  /// 成功回傳
  factory ApiResponse.success(dynamic data) {
    return ApiResponse(
      isSuccess: true,
      errorMsg: '',
      data: data,
    );
  }

  /// 錯誤回傳
  factory ApiResponse.error(String errorMsg) {
    return ApiResponse(
      isSuccess: false,
      errorMsg: errorMsg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'errorMsg': errorMsg,
      'data': data,
    };
  }

  String toJsonString() => jsonEncode(toJson());
}


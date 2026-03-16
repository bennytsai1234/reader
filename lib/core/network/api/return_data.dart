import 'dart:convert';

class ReturnData {
  final int code;
  final String? msg;
  final dynamic data;

  ReturnData({this.code = 200, this.msg = 'success', this.data});

  Map<String, dynamic> toJson() => {
    'code': code,
    'msg': msg,
    'data': data,
  };

  @override
  String toString() => jsonEncode(toJson());
}


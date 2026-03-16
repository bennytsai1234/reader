import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:uuid/uuid.dart';
import '../js_extensions.dart';
import '../js_encode_utils.dart';

extension JsCryptoExtensions on JsExtensions {
  void injectCryptoExtensions() {
    // 實作 java.createSymmetricCrypto
    runtime.onMessage('symmetricCrypto', (dynamic args) {
      final action = args[0].toString();
      final transformation = args[1].toString();
      final key = args[2];
      final iv = args[3];
      final data = args[4];
      final outputFormat = args[5].toString();

      return JsEncodeUtils.symmetricCrypto(
        action,
        transformation,
        key,
        iv,
        data,
        outputFormat: outputFormat,
      );
    });

    // 注入輔助函式
    runtime.onMessage(
      '_md5Encode',
      (dynamic args) => JsEncodeUtils.md5Encode(args.toString()),
    );
    runtime.onMessage(
      '_md5Encode16',
      (dynamic args) => JsEncodeUtils.md5Encode16(args.toString()),
    );
    runtime.onMessage(
      '_base64Encode',
      (dynamic args) => JsEncodeUtils.base64Encode(args.toString()),
    );
    runtime.onMessage('_base64Decode', (dynamic args) {
      final str = args is List ? args[0].toString() : args.toString();
      final charset =
          args is List && args.length > 1 ? args[1].toString() : 'UTF-8';
      return JsEncodeUtils.base64Decode(str, charset: charset);
    });
    runtime.onMessage(
      '_hexEncode',
      (dynamic args) => hex.encode(utf8.encode(args.toString())),
    );
    runtime.onMessage(
      '_hexDecode',
      (dynamic args) => utf8.decode(hex.decode(args.toString())),
    );
    runtime.onMessage('_randomUUID', (dynamic args) => const Uuid().v4());
  }
}


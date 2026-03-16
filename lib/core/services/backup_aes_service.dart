import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';

/// BackupAESService - (原 Android BackupAES.kt)
/// 用於加密備份中的敏感資訊（如 WebDav 密碼、伺服器配置）
class BackupAESService {
  static final BackupAESService _instance = BackupAESService._internal();
  factory BackupAESService() => _instance;
  BackupAESService._internal();

  /// 生成與 Android 對等的 16 byte Key
  Future<Uint8List?> _getKey() async {
    final prefs = await SharedPreferences.getInstance();
    final password = prefs.getString(PreferKey.localPassword) ?? '';
    if (password.isEmpty) return null;

    // MD5 編碼並取前 16 位元組 (原 Android BackupAES)
    final md5Bytes = md5.convert(utf8.encode(password)).bytes;
    return Uint8List.fromList(md5Bytes.sublist(0, 16));
  }

  /// 加密 (原 Android encryptBase64)
  Future<String> encrypt(String plainText) async {
    final keyBytes = await _getKey();
    if (keyBytes == null) return plainText;

    final key = enc.Key(keyBytes);
    // Android Hutool 默認使用 AES/ECB/PKCS5Padding (PKCS7 在 Flutter 中對等)
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
    final encrypted = encrypter.encrypt(plainText);
    return encrypted.base64;
  }

  /// 解密 (用於還原備份)
  Future<String> decrypt(String base64Text) async {
    final keyBytes = await _getKey();
    if (keyBytes == null) return base64Text;

    try {
      final key = enc.Key(keyBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
      return encrypter.decrypt64(base64Text);
    } catch (e) {
      // 若解密失敗，可能是密碼不對或原本就沒加密
      return base64Text;
    }
  }
}


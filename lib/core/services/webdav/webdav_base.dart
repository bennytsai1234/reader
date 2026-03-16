import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:legado_reader/core/constant/prefer_key.dart';
import '../backup_aes_service.dart';

/// WebDAVService 的基礎類別與客戶端管理
abstract class WebDAVBase extends ChangeNotifier {
  final BackupAESService aesService = BackupAESService();
  bool isSyncing = false;

  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(PreferKey.webDavUrl) ?? '';
    final user = prefs.getString(PreferKey.webDavAccount) ?? '';
    final pwdEnc = prefs.getString(PreferKey.webDavPassword) ?? '';
    return url.isNotEmpty && user.isNotEmpty && pwdEnc.isNotEmpty;
  }

  Future<webdav.Client> getClient() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(PreferKey.webDavUrl) ?? '';
    final user = prefs.getString(PreferKey.webDavAccount) ?? '';
    final pwdEnc = prefs.getString(PreferKey.webDavPassword) ?? '';
    
    if (url.isEmpty || user.isEmpty || pwdEnc.isEmpty) {
      throw Exception('WebDAV not configured');
    }

    final password = await aesService.decrypt(pwdEnc);
    
    final client = webdav.newClient(url, user: user, password: password);
    client.setConnectTimeout(8000);
    client.setSendTimeout(8000);
    client.setReceiveTimeout(8000);
    return client;
  }

  Future<bool> testConnection() async {
    try {
      final client = await getClient();
      await client.readDir('/');
      return true;
    } catch (e) {
      debugPrint('WebDAV Test Connection Failed: $e');
      return false;
    }
  }

  void setSyncState(bool val) {
    isSyncing = val;
    notifyListeners();
  }
}


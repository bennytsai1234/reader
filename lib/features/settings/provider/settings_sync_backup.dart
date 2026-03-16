import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'settings_base.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';
import 'package:legado_reader/core/services/webdav_service.dart';
import 'package:legado_reader/core/database/app_database.dart';
import 'package:legado_reader/core/di/injection.dart';

/// SettingsProvider 的同步與備份擴展
extension SettingsSyncBackup on SettingsProviderBase {
  Future<void> updateWebDav({required String url, required String user, required String password}) async {
    final provider = (this as dynamic);
    provider.webdavUrl = url; provider.webdavUser = user; provider.webdavPassword = password;
    provider.webdavEnabled = url.isNotEmpty && user.isNotEmpty && password.isNotEmpty;
    await save(PreferKey.webDavUrl, url);
    await save(PreferKey.webDavAccount, user);
    await save(PreferKey.webDavPassword, password);
    await save('webdav_enabled', provider.webdavEnabled);
    update();
  }

  Future<String?> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'legado_reader.db');
      final dbFile = File(path);
      if (!await dbFile.exists()) return null;
      final backupDir = await getApplicationDocumentsDirectory();
      final backupPath = join(backupDir.path, 'legado_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await dbFile.copy(backupPath);
      return backupPath;
    } catch (e) { debugPrint('備份失敗: $e'); return null; }
  }

  Future<bool> restoreDatabase(String backupPath) async {
    try {
      await getIt<AppDatabase>().close();
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'legado_reader.db');
      await File(backupPath).copy(path);
      return true;
    } catch (e) { debugPrint('還原失敗: $e'); return false; }
  }

  Future<String?> checkWebDavBackupSync() async {
    final provider = (this as dynamic);
    if (!provider.webdavEnabled || !provider.autoCheckNewBackup) return null;
    try {
      final backups = await WebDavService().listBackups();
      if (backups.isEmpty) return null;
      final lastFile = backups.first;
      final name = lastFile.name ?? '';
      final tsStr = name.replaceAll('backup_', '').replaceAll('.zip', '');
      final remoteTs = int.tryParse(tsStr) ?? 0;
      if (remoteTs > provider.lastBackup) return name;
    } catch (e) { debugPrint('Check WebDav sync failed: $e'); }
    return null;
  }
}


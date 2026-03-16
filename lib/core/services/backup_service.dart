import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/database/dao/read_record_dao.dart';
import 'package:legado_reader/core/database/dao/txt_toc_rule_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/utils/logger.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  /// 執行全量備份並返回 ZIP 檔案路徑
  Future<File?> createBackupZip() async {
    final tempDir = await getTemporaryDirectory();
    final backupFolder = Directory(p.join(tempDir.path, 'legado_backup'));
    if (await backupFolder.exists()) await backupFolder.delete(recursive: true);
    await backupFolder.create();

    try {
      // 1. 導出資料庫表為 JSON (對標 Android Backup.kt)
      await _writeJson(backupFolder, 'bookshelf.json', await getIt<BookDao>().getAll());
      await _writeJson(backupFolder, 'bookSource.json', await getIt<BookSourceDao>().getAllFull());
      await _writeJson(backupFolder, 'replaceRule.json', await getIt<ReplaceRuleDao>().getAll());
      await _writeJson(backupFolder, 'bookmark.json', await getIt<BookmarkDao>().getAll());
      await _writeJson(backupFolder, 'readRecord.json', await getIt<ReadRecordDao>().getAll());
      await _writeJson(backupFolder, 'txtTocRule.json', await getIt<TxtTocRuleDao>().getAll());

      // 2. 導出偏好設定 (對標 config.xml)
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> config = {};
      for (var key in prefs.getKeys()) {
        config[key] = prefs.get(key);
      }
      await File(p.join(backupFolder.path, 'config.json')).writeAsString(jsonEncode(config));

      // 3. 打包為 ZIP
      final encoder = ZipFileEncoder();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final zipPath = p.join(tempDir.path, 'backup-$dateStr.zip');
      
      encoder.create(zipPath);
      await for (var entity in backupFolder.list(recursive: true)) {
        if (entity is File) {
          encoder.addFile(entity);
        }
      }
      encoder.close();

      return File(zipPath);
    } catch (e) {
      Logger.e('建立備份 ZIP 失敗: $e');
      return null;
    }
  }

  Future<void> _writeJson(Directory folder, String name, List<dynamic> data) async {
    final file = File(p.join(folder.path, name));
    final jsonList = data.map((e) {
      try { return (e as dynamic).toJson(); } catch (_) { return e; }
    }).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
}

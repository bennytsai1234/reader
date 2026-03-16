import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:archive/archive_io.dart';
import 'webdav_base.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/replace_rule_dao.dart';
import 'package:legado_reader/core/database/dao/book_group_dao.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/database/dao/read_record_dao.dart';
import 'package:legado_reader/core/database/dao/rss_source_dao.dart';
import 'package:legado_reader/core/database/dao/rss_star_dao.dart';
import 'package:legado_reader/core/database/dao/dict_rule_dao.dart';
import 'package:legado_reader/core/database/dao/http_tts_dao.dart';
import 'package:legado_reader/core/database/dao/txt_toc_rule_dao.dart';
import '../restore_service.dart';
import 'package:legado_reader/core/di/injection.dart';

/// WebDAVService 的備份與還原邏輯擴展
mixin WebDAVBackup on WebDAVBase {
  Future<webdav.File?> lastBackUp() async {
    try {
      final client = await getClient();
      final files = await client.readDir('/legado');
      final backupFiles = files.cast<webdav.File>().where((f) => f.name != null && f.name!.startsWith('backup_') && f.name!.endsWith('.zip')).toList();
      if (backupFiles.isEmpty) return null;
      backupFiles.sort((a, b) {
        final timeA = a.mTime?.toString() ?? '';
        final timeB = b.mTime?.toString() ?? '';
        return timeB.compareTo(timeA);
      });
      return backupFiles.first;
    } catch (e) {
      debugPrint('Get last backup failed: $e');
      return null;
    }
  }

  Future<bool> backup() async {
    if (isSyncing) return false;
    setSyncState(true);
    try {
      final client = await getClient();
      await client.mkdir('/legado');
      final dir = await getTemporaryDirectory();
      final zipPath = '${dir.path}/legado_backup.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);

      final bookDao = getIt<BookDao>();
      final books = await bookDao.getAll();
      _addJsonToZip(encoder, 'bookshelf.json', books.map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookSource.json', (await getIt<BookSourceDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'replaceRule.json', (await getIt<ReplaceRuleDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookGroup.json', (await getIt<BookGroupDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'bookmark.json', (await getIt<BookmarkDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'readRecord.json', (await getIt<ReadRecordDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'rssSource.json', (await getIt<RssSourceDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'rssStar.json', (await getIt<RssStarDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'dictRule.json', (await getIt<DictRuleDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'httpTts.json', (await getIt<HttpTtsDao>().getAll()).map((e) => e.toJson()).toList(), dir);
      _addJsonToZip(encoder, 'txtTocRule.json', (await getIt<TxtTocRuleDao>().getAll()).map((e) => e.toJson()).toList(), dir);

      final prefs = await SharedPreferences.getInstance();
      final config = { for (var k in prefs.getKeys()) if (!k.startsWith('reader_')) k: prefs.get(k) };
      _addJsonToZip(encoder, 'config.json', [config], dir);

      encoder.close();
      await client.writeFromFile(zipPath, '/legado/legado_backup.zip');
      await prefs.setInt('last_backup', DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      debugPrint('Backup Failed: $e');
      return false;
    } finally {
      setSyncState(false);
    }
  }

  void _addJsonToZip(ZipFileEncoder encoder, String fileName, List<dynamic> data, Directory dir) {
    if (data.isEmpty) return;
    final file = File('${dir.path}/$fileName');
    file.writeAsStringSync(jsonEncode(data));
    encoder.addFile(file);
    file.deleteSync();
  }

  Future<bool> restoreFromFile(String remotePath) async {
    if (isSyncing) return false;
    setSyncState(true);
    try {
      final client = await getClient();
      final dir = await getTemporaryDirectory();
      final zipPath = '${dir.path}/legado_restore_temp.zip';
      final localFile = File(zipPath);
      await client.read2File(remotePath, localFile.path);
      final success = await RestoreService().restoreFromZip(localFile);
      if (await localFile.exists()) await localFile.delete();
      return success;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    } finally {
      setSyncState(false);
    }
  }
}



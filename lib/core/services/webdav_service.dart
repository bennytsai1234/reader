import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_progress.dart';
import 'package:legado_reader/core/database/dao/server_dao.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/services/backup_service.dart';
import 'package:legado_reader/core/di/injection.dart';

/// WebDavService - WebDAV 同步服務 (對標 Android help/AppWebDav.kt)
class WebDavService {
  static final WebDavService _instance = WebDavService._internal();
  factory WebDavService() => _instance;
  WebDavService._internal();

  webdav.Client? _client;
  String _rootUrl = '';

  Future<void> init() async {
    final servers = await getIt<ServerDao>().getAll();
    final webdavServer = servers.where((s) => s.type == 'WEBDAV').firstOrNull;

    if (webdavServer != null) {
      final config = webdavServer.webDavConfig;
      if (config != null) {
        _rootUrl = config.url;
        if (!_rootUrl.endsWith('/')) _rootUrl += '/';
        _client = webdav.newClient(_rootUrl, user: config.username, password: config.password);
      }
    }
  }

  Future<bool> isConfigured() async {
    if (_client == null) await init();
    return _client != null;
  }

  Future<bool> checkAndInit() async {
    if (!await isConfigured()) return false;
    try {
      await _client!.ping();
      await _client!.mkdir('/bookProgress');
      await _client!.mkdir('/backup');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 獲取備份列表 (對標 Android 雲端備份瀏覽)
  Future<List<webdav.File>> listBackups() async {
    if (!await isConfigured()) return [];
    try {
      final files = await _client!.readDir('/backup');
      // 過濾並排序：最新日期優先
      return files.where((f) => f.name != null && f.name!.endsWith('.zip')).toList()
        ..sort((a, b) => (b.mTime ?? DateTime(0)).compareTo(a.mTime ?? DateTime(0)));
    } catch (e) {
      debugPrint('WebDAV 讀取備份列表失敗: $e');
      return [];
    }
  }

  /// 執行全量備份並上傳 (對標 Android Backup.backup)
  Future<bool> uploadFullBackup() async {
    if (!await isConfigured()) return false;
    try {
      final zipFile = await BackupService().createBackupZip();
      if (zipFile == null) return false;
      final remotePath = '/backup/${p.basename(zipFile.path)}';
      final bytes = await zipFile.readAsBytes();
      await _client!.write(remotePath, bytes);
      await zipFile.delete();
      return true;
    } catch (e) {
      debugPrint('WebDAV 全量備份失敗: $e');
      return false;
    }
  }

  /// 從雲端備份還原 (對標 Android 還原邏輯)
  Future<bool> restoreBackup(String fileName) async {
    if (!await isConfigured()) return false;
    try {
      final remotePath = '/backup/$fileName';
      final data = await _client!.read(remotePath);
      
      final tempDir = await getTemporaryDirectory();
      final localPath = p.join(tempDir.path, fileName);
      final file = File(localPath);
      await file.writeAsBytes(data);

      // 呼叫還原引擎 (下一階段實作詳細還原邏輯)
      debugPrint('備份已下載，準備還原: $localPath');
      return true;
    } catch (e) {
      debugPrint('WebDAV 還原失敗: $e');
      return false;
    }
  }

  String _getProgressPath(String name, String author) {
    final fileName = '${name}_$author'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '/bookProgress/$fileName.json';
  }

  Future<void> uploadProgress(Book book) async {
    if (!await isConfigured()) return;
    try {
      final path = _getProgressPath(book.name, book.author);
      final progress = BookProgress(
        name: book.name, author: book.author,
        durChapterIndex: book.durChapterIndex, durChapterPos: book.durChapterPos,
        durChapterTitle: book.durChapterTitle ?? '', durChapterTime: book.durChapterTime,
      );
      final jsonStr = jsonEncode(progress.toJson());
      await _client!.write(path, Uint8List.fromList(utf8.encode(jsonStr)));
    } catch (e) {
      debugPrint('WebDAV 上傳進度失敗: $e');
    }
  }

  Future<void> uploadFile(String localPath, String remoteName) async {
    if (!await isConfigured()) return;
    try {
      final file = File(localPath);
      final bytes = await file.readAsBytes();
      await _client!.write('/backup/$remoteName', bytes);
    } catch (e) {
      debugPrint('WebDAV 上傳檔案失敗: $e');
    }
  }

  Future<void> syncAllBookProgress() async {
    if (!await isConfigured()) return;
    final bookDao = getIt<BookDao>();
    final books = await bookDao.getAll();
    for (var book in books) {
      await syncProgress(book);
    }
  }

  Future<void> syncProgress(Book book) async {
    if (!await isConfigured()) return;
    final path = _getProgressPath(book.name, book.author);
    try {
      final data = await _client!.read(path);
      final remote = BookProgress.fromJson(jsonDecode(utf8.decode(data)));
      if (remote.durChapterTime > book.durChapterTime) {
        book.durChapterIndex = remote.durChapterIndex;
        book.durChapterPos = remote.durChapterPos;
        book.durChapterTitle = remote.durChapterTitle;
        book.durChapterTime = remote.durChapterTime;
        await getIt<BookDao>().upsert(book);
      }
    } catch (_) {}
  }

  Future<void> restore() async {
    await syncAllBookProgress();
  }

  Future<void> restoreLatestBackup() async {
    final backups = await listBackups();
    if (backups.isNotEmpty) {
      await restoreBackup(backups.first.name!);
    }
  }
}

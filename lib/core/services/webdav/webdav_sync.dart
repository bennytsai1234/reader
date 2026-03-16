import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'webdav_base.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_progress.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';

/// WebDAVService 的進度同步與檔案傳輸邏輯擴展 (補全版)
mixin WebDAVSync on WebDAVBase {
  /// 上傳單本書籍進度
  Future<void> uploadBookProgress(Book book) async {
    if (!await isConfigured()) return;
    try {
      final client = await getClient();
      await client.mkdir('/legado/progress');
      final progress = BookProgress(
        name: book.name,
        author: book.author,
        durChapterIndex: book.durChapterIndex,
        durChapterPos: book.durChapterPos,
        durChapterTitle: book.durChapterTitle ?? '',
        durChapterTime: DateTime.now().millisecondsSinceEpoch,
      );
      final data = jsonEncode(progress.toJson());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${book.name.hashCode}.json');
      await file.writeAsString(data);
      await client.writeFromFile(file.path, '/legado/progress/${book.name.hashCode}.json');
    } catch (e) {
      debugPrint('Upload progress failed: $e');
    }
  }

  /// 同步所有書架書籍進度 (原 Android SyncService)
  Future<void> syncAllBookProgress() async {
    if (!await isConfigured()) return;
    setSyncState(true);
    try {
      final client = await getClient();
      final bookDao = getIt<BookDao>();
      final books = await bookDao.getAllInBookshelf();
      
      for (final book in books) {
        final remotePath = '/legado/progress/${book.name.hashCode}.json';
        try {
          // 嘗試下載遠端進度
          final dir = await getTemporaryDirectory();
          final localFile = File('${dir.path}/${book.name.hashCode}_sync.json');
          await client.read2File(remotePath, localFile.path);
          
          final content = await localFile.readAsString();
          final remoteProgress = BookProgress.fromJson(jsonDecode(content));
          
          // 如果遠端比較新，更新本地
          if (remoteProgress.durChapterTime > book.durChapterTime) {
            await bookDao.updateProgress(
              book.bookUrl, 
              remoteProgress.durChapterPos
            );
          } else {
            // 否則上傳本地進度
            await uploadBookProgress(book);
          }
        } catch (_) {
          // 遠端不存在，上傳本地
          await uploadBookProgress(book);
        }
      }
    } catch (e) {
      debugPrint('Sync all progress failed: $e');
    } finally {
      setSyncState(false);
    }
  }

  Future<void> uploadLocalBook(Book book, File file) async {
    try {
      final client = await getClient();
      await client.mkdir('/legado/books');
      final fileName = p.basename(file.path);
      await client.writeFromFile(file.path, '/legado/books/$fileName');
    } catch (e) {
      debugPrint('Upload book failed: $e');
    }
  }

  Future<File?> downloadLocalBook(Book book) async {
    try {
      final client = await getClient();
      final fileName = p.basename(book.bookUrl);
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/$fileName');
      await client.read2File('/legado/books/$fileName', localFile.path);
      return localFile;
    } catch (e) {
      debugPrint('Download book failed: $e');
      return null;
    }
  }

  Future<void> uploadFile(String localPath, String remoteName) async {
    try {
      final client = await getClient();
      await client.mkdir('/legado/export');
      await client.writeFromFile(localPath, '/legado/export/$remoteName');
    } catch (e) {
      debugPrint('Upload file failed: $e');
    }
  }
}


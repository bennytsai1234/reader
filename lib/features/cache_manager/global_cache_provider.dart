import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/di/injection.dart';

class GlobalCacheInfo {
  final String label;
  final int sizeInBytes;
  final VoidCallback onClear;

  GlobalCacheInfo({required this.label, required this.sizeInBytes, required this.onClear});

  String get sizeFormatted {
    if (sizeInBytes <= 0) return '0 B';
    // Simple formatting
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    if (sizeInBytes < 1024 * 1024 * 1024) return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class GlobalCacheProvider with ChangeNotifier {
  final ChapterDao _chapterDao = getIt<ChapterDao>();

  List<GlobalCacheInfo> _cacheItems = [];
  List<GlobalCacheInfo> get cacheItems => _cacheItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get totalSize => _cacheItems.fold(0, (sum, item) => sum + item.sizeInBytes);

  GlobalCacheProvider() {
    loadCacheInfo();
  }

  Future<void> loadCacheInfo() async {
    _isLoading = true;
    notifyListeners();

    final items = <GlobalCacheInfo>[];

    // 1. 資料庫章節內容快取
    final dbSize = await _chapterDao.getTotalContentSize();
    items.add(GlobalCacheInfo(
      label: '書籍正文快取 (資料庫)',
      sizeInBytes: dbSize,
      onClear: () async {
        await _chapterDao.clearAllContent();
        await loadCacheInfo();
      },
    ));

    // 2. 圖片快取 (如果有的話)
    final tempDir = await getTemporaryDirectory();
    final tempSize = await _getDirSize(tempDir);
    items.add(GlobalCacheInfo(
      label: '臨時檔案與圖片快取',
      sizeInBytes: tempSize,
      onClear: () async {
        await _clearDir(tempDir);
        await loadCacheInfo();
      },
    ));

    // 3. 字體檔案
    final appDocDir = await getApplicationDocumentsDirectory();
    final fontDir = Directory('${appDocDir.path}/fonts');
    final fontSize = await _getDirSize(fontDir);
    items.add(GlobalCacheInfo(
      label: '自訂字體檔案',
      sizeInBytes: fontSize,
      onClear: () async {
        // 通常不建議一鍵清理字體，除非使用者確定
        if (await fontDir.exists()) {
          await fontDir.delete(recursive: true);
          await fontDir.create();
        }
        await loadCacheInfo();
      },
    ));

    _cacheItems = items;
    _isLoading = false;
    notifyListeners();
  }

  Future<int> _getDirSize(Directory dir) async {
    var totalSize = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating dir size: $e');
    }
    return totalSize;
  }

  Future<void> _clearDir(Directory dir) async {
    try {
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (var entity in entities) {
          await entity.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error clearing dir: $e');
    }
  }
}



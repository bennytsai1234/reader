import 'dart:convert';
import 'book_base.dart';

/// Book 業務邏輯擴展
extension BookLogic on BookBase {
  void setVariable(String key, String value) {
    Map<String, String> map;
    if (variable != null && variable!.isNotEmpty) {
      try {
        final decoded = jsonDecode(variable!);
        map = (decoded as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
      } catch (_) { map = {}; }
    } else { map = {}; }
    
    map[key] = value;
    variable = jsonEncode(map);
  }

  /// 書籍遷移邏輯 (原 Android Book.migrateTo)
  BookBase migrateTo(BookBase newBook, List<dynamic>? newChapters) {
    var alignedIndex = durChapterIndex;
    if (newChapters != null && newChapters.isNotEmpty) {
      alignedIndex = _getDurChapter(
        durChapterIndex,
        durChapterTitle,
        newChapters,
        totalChapterNum,
      );
    }

    // 透過 Book (子類) 的 copyWith 實現，這裡假設 Book 已經實作了 copyWith
    return (this as dynamic).copyWith(
      group: group,
      order: order,
      canUpdate: canUpdate,
      durChapterIndex: alignedIndex,
      durChapterPos: durChapterPos,
      durChapterTitle: alignedIndex < (newChapters?.length ?? 0)
          ? newChapters![alignedIndex].title
          : durChapterTitle,
      durChapterTime: durChapterTime,
      readConfig: readConfig,
    );
  }

  int _getDurChapter(
    int oldIndex,
    String? oldName,
    List<dynamic> newChapters,
    int oldTotalNum,
  ) {
    if (oldIndex <= 0) return 0;
    if (newChapters.isEmpty) return oldIndex;

    final newSize = newChapters.length;
    if (oldName != null && oldName.isNotEmpty) {
      for (var i = 0; i < newSize; i++) {
        if (newChapters[i].title == oldName) return i;
      }
    }

    final oldChapterNum = _extractChapterNum(oldName);
    if (oldChapterNum != null) {
      for (var i = 0; i < newSize; i++) {
        if (_extractChapterNum(newChapters[i].title) == oldChapterNum) return i;
      }
    }

    var estimateIndex = oldIndex;
    if (oldTotalNum > 0) {
      estimateIndex = (oldIndex * newSize / oldTotalNum).round();
    }

    return estimateIndex.clamp(0, newSize - 1);
  }

  int? _extractChapterNum(String? title) {
    if (title == null) return null;
    final match = RegExp(r'第\s*(\d+)\s*[章节篇回集话]').firstMatch(title);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }
}


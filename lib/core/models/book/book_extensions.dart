import 'dart:convert';
import 'book_base.dart';

/// Book 擴展 - 類型感知與業務屬性
/// (原 Android BookExtensions.kt)
extension BookExtensions on BookBase {
  // --- 延遲加載變數 Map ---
  Map<String, String> get variableMap {
    if (variable != null && variable!.isNotEmpty) {
      try {
        final decoded = jsonDecode(variable!);
        if (decoded is Map) {
          return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }
    return {};
  }

  // --- 類型感知 ---
  bool get isAudio => (type & 2) != 0; // BookType.audio = 2
  bool get isImage => (type & 4) != 0; // BookType.image = 4
  bool get isEpub => bookUrl.toLowerCase().endsWith('.epub');
  bool get isLocal => origin == 'local' || origin.startsWith('webdav');
  bool get isUpdate => lastCheckCount > 0;

  // --- 顯示輔助 ---
  String getRealAuthor() => author.replaceAll(RegExp(r'\(.*?\)|\[.*?\]|（.*?）|【.*?】'), '').trim();
  String? getDisplayCover() => (customCoverUrl == null || customCoverUrl!.isEmpty) ? coverUrl : customCoverUrl;
  String? getDisplayIntro() => (customIntro == null || customIntro!.isEmpty) ? intro : customIntro;

  /// 是否使用淨化替換規則
  bool getUseReplaceRule() {
    final explicitValue = readConfig?.useReplaceRule;
    if (explicitValue != null) return explicitValue;
    if (isImage || isAudio || isEpub) return false;
    return true;
  }

  bool getReSegment() => readConfig?.reSegment ?? false;

  // --- 進度與模擬計算 (對齊 Android Book.kt) ---
  int get simulatedTotalChapterNum {
    if (readConfig?.readSimulating ?? false) {
      // 簡單實作模擬邏輯：起始章節 + 天數 * 每日章節
      return (readConfig?.startChapter ?? 0) + 100; // 簡化 Placeholder
    }
    return totalChapterNum;
  }

  String get durChapterPercent {
    if (totalChapterNum <= 0) return '0.0%';
    final percent = (durChapterIndex / totalChapterNum) * 100;
    return '${percent.toStringAsFixed(1)}%';
  }
}

/// Book 位元運算擴展
extension BookBitwiseExtension on BookBase {
  bool isType(int typeMask) => (type & typeMask) != 0;
  void addType(int typeMask) => type |= typeMask;
  void removeType(int typeMask) => type &= ~typeMask;

  bool hasGroup(int groupIdMask) {
    if (groupIdMask <= 0) return true;
    return (group & groupIdMask) != 0;
  }
  void addGroup(int groupIdMask) => group |= groupIdMask;
  void removeGroup(int groupIdMask) => group &= ~groupIdMask;
}


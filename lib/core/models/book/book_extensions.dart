import 'dart:convert';
import 'package:legado_reader/core/constant/book_type.dart';
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

  // --- 類型感知 (對齊 Android BookType 位元) ---
  bool get isAudio => (type & BookType.audio) != 0;
  bool get isImage => (type & BookType.image) != 0;
  bool get isText => (type & BookType.text) != 0;
  bool get isEpub => bookUrl.toLowerCase().endsWith('.epub');
  bool get isLocal => origin == BookType.localTag || origin.startsWith(BookType.webDavTag);
  bool get isUpdate => lastCheckCount > 0;

  // --- 顯示輔助 ---
  String getRealAuthor() => author.replaceAll(RegExp(r'\s+作\s*者.*|\s+\S+\s+著'), '').trim();
  String? getDisplayCover() => (customCoverUrl == null || customCoverUrl!.isEmpty) ? coverUrl : customCoverUrl;
  String? getDisplayIntro() => (customIntro == null || customIntro!.isEmpty) ? intro : customIntro;

  /// 是否使用淨化替換規則
  bool getUseReplaceRule() {
    final explicitValue = readConfig?.useReplaceRule;
    if (explicitValue != null) return explicitValue;
    // 圖片類、音訊類、Epub 本地 預設關閉淨化
    if (isImage || isAudio || isEpub) return false;
    // TODO: 這裡應串接 AppConfig.replaceEnableDefault (預設開啟)
    return true;
  }

  bool getReSegment() => readConfig?.reSegment ?? false;

  int getPageAnim() {
    int? pageAnim = readConfig?.pageAnim;
    if (pageAnim != null && pageAnim >= 0) return pageAnim;
    // 圖片類預設滾動翻頁 (PageAnim.scrollPageAnim = 3)
    if (isImage) return 3;
    // TODO: 這裡應串接 ReadBookConfig.pageAnim (預設 0)
    return 0;
  }

  // --- 進度與模擬計算 (對齊 Android Book.kt) ---
  int get simulatedTotalChapterNum {
    if (readConfig?.readSimulating ?? false) {
      // 這裡應實作真正的模擬邏輯：起始章節 + (今天 - 開始日期) * 每日章節
      return totalChapterNum; 
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


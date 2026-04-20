import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/config/app_config.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/services/tts_service.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reader_provider_base.dart';

/// ReaderProvider 的設置管理擴展
mixin ReaderSettingsMixin on ReaderProviderBase {
  double fontSize = 18.0;
  double lineHeight = 1.5;
  double paragraphSpacing = 1.0;
  double letterSpacing = 0.0;
  int textIndent = 2;
  bool textFullJustify = true;
  int themeIndex = 0;
  int lastDayThemeIndex = 0;
  int lastNightThemeIndex = 0;
  double brightness = 1.0;
  int chineseConvert = 0;
  int pageTurnMode = 1; // 預設平移（PageAnim.slide=1）
  bool showAddToShelfAlert = true;

  /// 設定變更時的回調，由 ReaderProvider 注入
  /// 觸發分頁快取清除 + 重新分頁
  VoidCallback? onSettingsChangedRepaginate;
  VoidCallback? onBeforeRepaginate;

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    fontSize = p.getDouble(PreferKey.readerFontSize) ?? 18.0;
    lineHeight = p.getDouble(PreferKey.readerLineHeight) ?? 1.5;
    paragraphSpacing = p.getDouble(PreferKey.readerParagraphSpacing) ?? 1.0;
    textIndent = p.getInt(PreferKey.readerTextIndent) ?? 2;
    themeIndex = p.getInt(PreferKey.readerThemeIndex) ?? 0;
    brightness = p.getDouble(PreferKey.readerBrightness) ?? 1.0;
    pageTurnMode = p.getInt(PreferKey.readerPageTurnMode) ?? 1;
    AppConfig.readerPageAnim = pageTurnMode;
    chineseConvert = p.getInt(PreferKey.readerChineseConvert) ?? 0;
    showAddToShelfAlert = p.getBool(PreferKey.showAddToShelfAlert) ?? true;
    lastDayThemeIndex =
        p.getInt('reader_day_theme_index') ?? _fallbackDayThemeIndex();
    lastNightThemeIndex =
        p.getInt('reader_night_theme_index') ?? _fallbackNightThemeIndex();
    _normalizeDayNightThemeIndexes();

    final ttsRate = p.getDouble(PreferKey.readerTtsRate) ?? 1.0;
    final ttsPitch = p.getDouble(PreferKey.readerTtsPitch) ?? 1.0;
    final ttsLang = p.getString(PreferKey.readerTtsLanguage);

    TTSService().setRate(ttsRate);
    TTSService().setPitch(ttsPitch);
    if (ttsLang != null) TTSService().setLanguage(ttsLang);

    final actionsStr =
        p.getString(PreferKey.readerClickActions) ?? '0,0,0,0,0,0,0,0,0';
    clickActions = actionsStr.split(',').map((e) => int.parse(e)).toList();
    notifyListeners();
  }

  Future<void> saveSetting(String k, dynamic v) async {
    final p = await SharedPreferences.getInstance();
    final fk = 'reader_$k';
    if (v is double) {
      await p.setDouble(fk, v);
    } else if (v is int) {
      await p.setInt(fk, v);
    } else if (v is bool) {
      await p.setBool(fk, v);
    } else if (v is String) {
      await p.setString(fk, v);
    }
  }

  void setFontSize(double s) {
    fontSize = s;
    saveSetting('font_size', s);
    _triggerRepaginate();
  }

  void setLineHeight(double v) {
    lineHeight = v;
    saveSetting('line_height', v);
    _triggerRepaginate();
  }

  void setParagraphSpacing(double v) {
    paragraphSpacing = v;
    saveSetting('paragraph_spacing', v);
    _triggerRepaginate();
  }

  void setLetterSpacing(double v) {
    letterSpacing = v;
    saveSetting('letter_spacing', v);
    _triggerRepaginate();
  }

  void setTextFullJustify(bool v) {
    textFullJustify = v;
    saveSetting('text_full_justify', v);
    _triggerRepaginate();
  }

  void setTextIndent(int v) {
    textIndent = v;
    saveSetting('text_indent', v);
    _triggerRepaginate();
  }

  void setPageTurnMode(int v) {
    pageTurnMode = v;
    AppConfig.readerPageAnim = v;
    saveSetting('page_turn_mode', v);
    notifyListeners();
  }

  void setTheme(int i) {
    themeIndex = i;
    saveSetting('theme_index', i);
    _rememberDayNightThemeIndex(i);
    _triggerRepaginate();
  }

  bool get isCurrentThemeDark => _isThemeDark(themeIndex);

  int get dayNightToggleTargetThemeIndex =>
      isCurrentThemeDark ? lastDayThemeIndex : lastNightThemeIndex;

  bool get willToggleToDarkTheme =>
      _isThemeDark(dayNightToggleTargetThemeIndex);

  String get dayNightToggleLabel => willToggleToDarkTheme ? '夜間' : '日間';

  String get dayNightToggleTooltip =>
      willToggleToDarkTheme ? '切換到夜間主題' : '切換到白天主題';

  IconData get dayNightToggleIcon =>
      willToggleToDarkTheme
          ? Icons.dark_mode_rounded
          : Icons.light_mode_rounded;

  void toggleDayNightTheme() {
    final target = dayNightToggleTargetThemeIndex;
    if (target == themeIndex) {
      final fallback =
          isCurrentThemeDark
              ? _fallbackDayThemeIndex()
              : _fallbackNightThemeIndex();
      if (fallback != themeIndex) {
        setTheme(fallback);
      }
      return;
    }
    setTheme(target);
  }

  void setBrightness(double v) {
    brightness = v;
    saveSetting('brightness', v);
    notifyListeners();
  }

  void _triggerRepaginate() {
    onBeforeRepaginate?.call();
    onSettingsChangedRepaginate?.call();
  }

  void _rememberDayNightThemeIndex(int index) {
    if (_isThemeDark(index)) {
      lastNightThemeIndex = index;
      saveSetting('night_theme_index', index);
    } else {
      lastDayThemeIndex = index;
      saveSetting('day_theme_index', index);
    }
  }

  bool _isThemeDark(int index) {
    if (AppTheme.readingThemes.isEmpty) return index != 0;
    final safeIndex = index.clamp(0, AppTheme.readingThemes.length - 1).toInt();
    return AppTheme.readingThemes[safeIndex].backgroundColor
            .computeLuminance() <
        0.5;
  }

  int _fallbackDayThemeIndex() {
    if (AppTheme.readingThemes.isEmpty) return 0;
    for (var i = 0; i < AppTheme.readingThemes.length; i++) {
      if (!_isThemeDark(i)) return i;
    }
    return 0;
  }

  int _fallbackNightThemeIndex() {
    if (AppTheme.readingThemes.isEmpty) return 1;
    for (var i = AppTheme.readingThemes.length - 1; i >= 0; i--) {
      if (_isThemeDark(i)) return i;
    }
    return (AppTheme.readingThemes.length - 1).clamp(0, 1 << 20).toInt();
  }

  void _normalizeDayNightThemeIndexes() {
    if (AppTheme.readingThemes.isEmpty) {
      lastDayThemeIndex = 0;
      lastNightThemeIndex = 1;
      return;
    }
    lastDayThemeIndex =
        lastDayThemeIndex.clamp(0, AppTheme.readingThemes.length - 1).toInt();
    lastNightThemeIndex =
        lastNightThemeIndex.clamp(0, AppTheme.readingThemes.length - 1).toInt();
    _rememberDayNightThemeIndex(themeIndex);
    if (_isThemeDark(lastDayThemeIndex)) {
      lastDayThemeIndex = _fallbackDayThemeIndex();
    }
    if (!_isThemeDark(lastNightThemeIndex)) {
      lastNightThemeIndex = _fallbackNightThemeIndex();
    }
  }
}

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
  double brightness = 1.0;
  int chineseConvert = 0;
  int pageTurnMode = 0;

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    fontSize = p.getDouble('reader_font_size') ?? 18.0;
    lineHeight = p.getDouble('reader_line_height') ?? 1.5;
    paragraphSpacing = p.getDouble('reader_paragraph_spacing') ?? 1.0;
    textIndent = p.getInt('reader_text_indent') ?? 2;
    themeIndex = p.getInt('reader_theme_index') ?? 0;
    brightness = p.getDouble('reader_brightness') ?? 0.5;
    pageTurnMode = p.getInt('reader_page_turn_mode') ?? 0;
    chineseConvert = p.getInt('reader_chinese_convert_v2') ?? 0;
    final actionsStr = p.getString('reader_click_actions') ?? '2,2,1,2,0,1,2,1,1';
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

  void setFontSize(double s) { fontSize = s; saveSetting('font_size', s); clearReaderCache(); (this as dynamic).doPaginate(); }
  void setLineHeight(double v) { lineHeight = v; saveSetting('line_height', v); clearReaderCache(); (this as dynamic).doPaginate(); }
  void setTextFullJustify(bool v) { textFullJustify = v; saveSetting('text_full_justify', v); clearReaderCache(); (this as dynamic).doPaginate(); }
  void setTextIndent(int v) { textIndent = v; saveSetting('text_indent', v); clearReaderCache(); (this as dynamic).doPaginate(); }
  void setPageTurnMode(int v) { pageTurnMode = v; saveSetting('page_turn_mode', v); notifyListeners(); }
  void setTheme(int i) { themeIndex = i; saveSetting('theme_index', i); clearReaderCache(); (this as dynamic).doPaginate(); }
  void setBrightness(double v) { brightness = v; saveSetting('brightness', v); notifyListeners(); }
  
  void clearReaderCache() { chapterCache.clear(); chapterContentCache.clear(); }
}


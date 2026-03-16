import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';
import 'package:legado_reader/core/services/web_service.dart';
import 'package:legado_reader/core/services/webdav_service.dart';
import 'provider/settings_base.dart';

export 'provider/settings_base.dart';
export 'provider/settings_ui_theme.dart';
export 'provider/settings_reading.dart';
export 'provider/settings_sync_backup.dart';
export 'provider/settings_advanced.dart';

/// SettingsProvider - 設置提供者 (重構後)
/// (原 Android help/config/AppConfig.kt)
class SettingsProvider extends SettingsProviderBase {
  // Web 服務
  bool webServiceEnabled = false;

  // WebDAV
  String webdavUrl = '';
  String webdavUser = '';
  String webdavPassword = '';
  String webdavSubDir = '';
  String deviceName = '';
  bool webdavEnabled = false;

  bool appCrash = false;
  bool enableReadRecord = true;
  String localPassword = '';
  int lastBackup = 0;
  int lastVersionCode = 0;
  bool privacyAgreed = false;

  // 封面進階設定
  int coverSearchPriority = 0;
  int coverTimeout = 5000;
  String globalCoverRule = '';

  // --- 主題色彩設定 ---
  bool transparentStatusBar = true;
  bool immNavigationBar = true;
  Color dayPrimaryColor = Colors.brown;
  Color dayAccentColor = Colors.red;
  Color dayBackgroundColor = Colors.grey.shade100;
  Color dayBottomBackgroundColor = Colors.grey.shade200;
  Color nightPrimaryColor = Colors.blueGrey.shade600;
  Color nightAccentColor = Colors.deepOrange.shade800;
  Color nightBackgroundColor = Colors.grey.shade900;
  Color nightBottomBackgroundColor = Colors.grey.shade800;
  String dayBackgroundImage = '';
  String nightBackgroundImage = '';

  // --- 閱讀設定 ---
  bool hideStatusBar = false;
  bool hideNavigationBar = false;
  bool readBodyToLh = true;
  bool paddingDisplayCutouts = false;
  bool useZhLayout = false;
  bool textFullJustify = true;
  bool textBottomJustify = true;
  bool mouseWheelPage = true;
  bool volumeKeyPage = true;
  bool volumeKeyPageOnPlay = false;
  bool keyPageOnLongPress = false;
  bool autoChangeSource = true;
  bool selectText = true;
  bool showBrightnessView = true;
  bool noAnimScrollPage = false;
  bool previewImageByClick = false;
  bool optimizeRender = false;
  bool disableReturnKey = false;
  bool expandTextMenu = false;
  bool showReadTitleAddition = true;
  bool readBarStyleFollowPage = false;

  // --- 備份設定 ---
  bool syncBookProgress = true;
  bool syncBookProgressPlus = false;
  bool onlyLatestBackup = true;
  bool autoCheckNewBackup = true;
  bool autoBackup = false;

  // --- 朗讀設定 ---
  bool ignoreAudioFocusAloud = false;
  bool pauseReadAloudWhilePhoneCalls = false;
  bool readAloudWakeLock = false;
  bool systemMediaControlCompatibilityChange = false;
  bool mediaButtonPerNext = false;
  bool readAloudByPage = false;
  bool streamReadAloudAudio = false;
  double speechRate = 0.5;
  double speechPitch = 1.0;
  double speechVolume = 1.0;

  // --- 歡迎介面與圖標 ---
  String welcomeImage = '';
  String welcomeImageDark = '';
  bool welcomeShowText = true;
  bool welcomeShowIcon = true;
  String launcherIcon = '';

  // 其他
  bool recordLog = false;

  // --- 缺失屬性補全 ---
  bool autoRefresh = true;
  bool defaultToRead = false;
  bool showDiscovery = true;
  bool showRss = true;
  int threadCount = 4;
  String userAgent = '';
  bool antiAlias = true;
  bool replaceEnableDefault = true;
  bool enableCronet = false;
  bool webServiceWakeLock = true;
  String bookStorageDir = '';
  bool ignoreAudioFocus = false;
  bool autoClearExpired = true;
  bool mediaButtonOnExit = true;
  bool readAloudByMediaButton = false;
  bool showAddToShelfAlert = true;
  bool showMangaUi = true;

  // --- Setter 補全 ---
  void setWebServiceEnabled(bool v) async {
    webServiceEnabled = v;
    if (v) {
      await WebService().start();
    } else {
      await WebService().stop();
    }
    notifyListeners();
  }

  void setAutoRefresh(bool v) { autoRefresh = v; save('auto_refresh', v); update(); }
  void setDefaultToRead(bool v) { defaultToRead = v; save('default_to_read', v); update(); }
  void setShowDiscovery(bool v) { showDiscovery = v; save('show_discovery', v); update(); }
  void setShowRss(bool v) { showRss = v; save('show_rss', v); update(); }
  void setThreadCount(int v) { threadCount = v; save('thread_count', v); update(); }
  void setUserAgent(String v) { userAgent = v; save('user_agent', v); update(); }
  void setAntiAlias(bool v) { antiAlias = v; save('anti_alias', v); update(); }
  void setReplaceEnableDefault(bool v) { replaceEnableDefault = v; save('replace_enable_default', v); update(); }
  void setEnableCronet(bool v) { enableCronet = v; save('enable_cronet', v); update(); }
  void setWebServiceWakeLock(bool v) { webServiceWakeLock = v; save('web_service_wake_lock', v); update(); }
  void setBookStorageDir(String v) { bookStorageDir = v; save('book_storage_dir', v); update(); }
  void setIgnoreAudioFocus(bool v) { ignoreAudioFocus = v; save('ignore_audio_focus', v); update(); }
  void setAutoClearExpired(bool v) { autoClearExpired = v; save('auto_clear_expired', v); update(); }
  void setMediaButtonOnExit(bool v) { mediaButtonOnExit = v; save('media_button_on_exit', v); update(); }
  void setReadAloudByMediaButton(bool v) { readAloudByMediaButton = v; save('read_aloud_by_media_button', v); update(); }
  void setShowAddToShelfAlert(bool v) { showAddToShelfAlert = v; save('show_add_to_shelf_alert', v); update(); }
  void setShowMangaUi(bool v) { showMangaUi = v; save('show_manga_ui', v); update(); }

  // --- 主題與備份 Setter 補全 ---
  void setTransparentStatusBar(bool v) { transparentStatusBar = v; save('transparent_status_bar', v); update(); }
  void setImmNavigationBar(bool v) { immNavigationBar = v; save('imm_navigation_bar', v); update(); }
  void setDayAccentColor(Color c) { dayAccentColor = c; save('day_accent_color', c.toARGB32()); update(); }
  void setDayBackgroundColor(Color c) { dayBackgroundColor = c; save('day_background_color', c.toARGB32()); update(); }
  void setDayBottomBackgroundColor(Color c) { dayBottomBackgroundColor = c; save('day_bottom_background_color', c.toARGB32()); update(); }
  void setNightAccentColor(Color c) { nightAccentColor = c; save('night_accent_color', c.toARGB32()); update(); }
  void setNightBackgroundColor(Color c) { nightBackgroundColor = c; save('night_background_color', c.toARGB32()); update(); }
  void setNightBottomBackgroundColor(Color c) { nightBottomBackgroundColor = c; save('night_bottom_background_color', c.toARGB32()); update(); }

  void setSyncBookProgress(bool v) { syncBookProgress = v; save('sync_book_progress', v); update(); }
  void setSyncBookProgressPlus(bool v) { syncBookProgressPlus = v; save('sync_book_progress_plus', v); update(); }
  void setOnlyLatestBackup(bool v) { onlyLatestBackup = v; save('only_latest_backup', v); update(); }
  void setAutoCheckNewBackup(bool v) { autoCheckNewBackup = v; save('auto_check_new_backup', v); update(); }
  void setAutoBackup(bool v) { autoBackup = v; save('auto_backup', v); update(); }

  void setReadBodyToLh(bool v) { readBodyToLh = v; save('read_body_to_lh', v); update(); }
  void setPaddingDisplayCutouts(bool v) { paddingDisplayCutouts = v; save('padding_display_cutouts', v); update(); }
  void setUseZhLayout(bool v) { useZhLayout = v; save('use_zh_layout', v); update(); }
  void setTextFullJustify(bool v) { textFullJustify = v; save('text_full_justify', v); update(); }
  void setTextBottomJustify(bool v) { textBottomJustify = v; save('text_bottom_justify', v); update(); }
  void setMouseWheelPage(bool v) { mouseWheelPage = v; save('mouse_wheel_page', v); update(); }
  void setVolumeKeyPageOnPlay(bool v) { volumeKeyPageOnPlay = v; save('volume_key_page_on_play', v); update(); }
  void setKeyPageOnLongPress(bool v) { keyPageOnLongPress = v; save('key_page_on_long_press', v); update(); }
  void setSelectText(bool v) { selectText = v; save('select_text', v); update(); }
  void setShowBrightnessView(bool v) { showBrightnessView = v; save('show_brightness_view', v); update(); }
  void setNoAnimScrollPage(bool v) { noAnimScrollPage = v; save('no_anim_scroll_page', v); update(); }
  void setPreviewImageByClick(bool v) { previewImageByClick = v; save('preview_image_by_click', v); update(); }
  void setDisableReturnKey(bool v) { disableReturnKey = v; save('disable_return_key', v); update(); }
  void setExpandTextMenu(bool v) { expandTextMenu = v; save('expand_text_menu', v); update(); }
  void setShowReadTitleAddition(bool v) { showReadTitleAddition = v; save('show_read_title_addition', v); update(); }
  void setReadBarStyleFollowPage(bool v) { readBarStyleFollowPage = v; save('read_bar_style_follow_page', v); update(); }

  void setWelcomeShowIcon(bool v) { welcomeShowIcon = v; save('welcome_show_icon', v); update(); }
  void setWelcomeImageDark(String v) { welcomeImageDark = v; save('welcome_image_dark', v); update(); }
  void setWelcomeShowTextDark(bool v) { /* Placeholder */ }
  void setWelcomeShowIconDark(bool v) { /* Placeholder */ }
  bool get welcomeShowTextDark => true;
  bool get welcomeShowIconDark => true;

  void setLastVersionCode(int v) { lastVersionCode = v; save('last_version_code', v); update(); }

  // --- 朗讀與 WebDAV Setter 補全 ---
  void setIgnoreAudioFocusAloud(bool v) { ignoreAudioFocusAloud = v; save('ignore_audio_focus_aloud', v); update(); }
  void setPauseReadAloudWhilePhoneCalls(bool v) { pauseReadAloudWhilePhoneCalls = v; save('pause_read_aloud_while_calls', v); update(); }
  void setReadAloudWakeLock(bool v) { readAloudWakeLock = v; save('read_aloud_wake_lock', v); update(); }
  void setSystemMediaControlCompatibilityChange(bool v) { systemMediaControlCompatibilityChange = v; save('system_media_control_compat', v); update(); }
  void setMediaButtonPerNext(bool v) { mediaButtonPerNext = v; save('media_button_per_next', v); update(); }
  void setReadAloudByPage(bool v) { readAloudByPage = v; save('read_aloud_by_page', v); update(); }
  void setStreamReadAloudAudio(bool v) { streamReadAloudAudio = v; save('stream_read_aloud_audio', v); update(); }
  void setWebdavSubDir(String v) { webdavSubDir = v; save('webdav_sub_dir', v); update(); }
  void setDeviceName(String v) { deviceName = v; save('device_name', v); update(); }
  void setLastBackup(int v) { lastBackup = v; save('last_backup', v); update(); }

  Future<String?> checkWebDavBackupSync() async {
    final backups = await WebDavService().listBackups();
    if (backups.isNotEmpty) {
      return backups.first.name;
    }
    return null;
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(PreferKey.themeMode) ?? 'system';
    themeMode = parseThemeMode(mode);

    final lang = prefs.getString(PreferKey.language) ?? 'system';
    locale = parseLocale(lang);

    welcomeImage = prefs.getString(PreferKey.welcomeImage) ?? '';
    welcomeShowText = prefs.getBool(PreferKey.welcomeShowText) ?? true;
    launcherIcon = prefs.getString(PreferKey.launcherIcon) ?? '';
    dayBackgroundImage = prefs.getString(PreferKey.bgImage) ?? '';
    nightBackgroundImage = prefs.getString(PreferKey.bgImageN) ?? '';

    webdavUrl = prefs.getString(PreferKey.webDavUrl) ?? '';
    webdavUser = prefs.getString(PreferKey.webDavAccount) ?? '';
    webdavPassword = prefs.getString(PreferKey.webDavPassword) ?? '';
    webdavEnabled = webdavUrl.isNotEmpty && webdavUser.isNotEmpty;

    lastBackup = prefs.getInt('last_backup') ?? 0;
    coverSearchPriority = prefs.getInt('cover_search_priority') ?? 0;
    coverTimeout = prefs.getInt('cover_timeout') ?? 5000;
    globalCoverRule = prefs.getString('global_cover_rule') ?? '';

    hideStatusBar = prefs.getBool('hide_status_bar') ?? false;
    hideNavigationBar = prefs.getBool('hide_navigation_bar') ?? false;
    volumeKeyPage = prefs.getBool('volume_key_page') ?? true;
    autoChangeSource = prefs.getBool('auto_change_source') ?? true;
    optimizeRender = prefs.getBool('optimize_render') ?? false;

    speechRate = prefs.getDouble(PreferKey.ttsSpeechRate) ?? 0.5;
    speechPitch = prefs.getDouble('speech_pitch') ?? 1.0;
    speechVolume = prefs.getDouble('speech_volume') ?? 1.0;

    privacyAgreed = prefs.getBool('privacy_agreed') ?? false;
    recordLog = prefs.getBool('record_log') ?? false;

    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    locale = parseLocale(lang);
    await save(PreferKey.language, lang);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await save(PreferKey.themeMode, mode.toString().split('.').last);
    notifyListeners();
  }
}


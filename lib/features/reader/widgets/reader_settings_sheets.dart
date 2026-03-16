import 'package:flutter/material.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'settings/interface_setting_sheet.dart';
import 'settings/advanced_setting_sheet.dart';

class ReaderSettingsSheets {
  /// 顯示界面設定 (主題、排版)
  static void showInterfaceSettings(BuildContext context, ReaderProvider provider) {
    InterfaceSettingSheet.show(context, provider);
  }

  /// 顯示進階設定 (系統、TTS、WebDAV)
  static void showMoreSettings(BuildContext context, ReaderProvider provider) {
    AdvancedSettingSheet.show(context, provider);
  }

  /// 舊代碼相容方法
  static void showTypography(BuildContext context, ReaderProvider provider) {
    InterfaceSettingSheet.show(context, provider);
  }

  static void showTheme(BuildContext context, ReaderProvider provider) {
    InterfaceSettingSheet.show(context, provider);
  }

  static void showPageTurnMode(BuildContext context, ReaderProvider provider) {
    InterfaceSettingSheet.show(context, provider);
  }
}


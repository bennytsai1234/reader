import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/auto_read_dialog.dart';
import 'package:inkpage_reader/features/reader/models/reader_tap_action.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/tts_dialog.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_settings_sheets.dart';
import 'package:inkpage_reader/features/replace_rule/replace_rule_page.dart';
import 'package:inkpage_reader/features/search/search_page.dart';
import 'package:inkpage_reader/features/settings/settings_page.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';

class ReaderPageActionDispatcher {
  const ReaderPageActionDispatcher();

  void handleContentTapUp(
    BuildContext context,
    ReaderProvider provider,
    TapUpDetails details,
  ) {
    _dispatchTapZoneAction(
      provider,
      position: details.localPosition,
      viewportSize: MediaQuery.sizeOf(context),
    );
  }

  void openDrawer(GlobalKey<ScaffoldState> scaffoldKey) {
    scaffoldKey.currentState?.openDrawer();
  }

  void showTtsDialog(BuildContext context) {
    TtsDialog.show(context);
  }

  void openMainMenuFromAutoReadDialog(
    BuildContext context,
    ReaderProvider provider,
  ) {
    Navigator.pop(context);
    provider.toggleControls();
  }

  void openDrawerFromAutoReadDialog(BuildContext context) {
    Navigator.pop(context);
    Scaffold.of(context).openDrawer();
  }

  void stopAutoPageFromDialog(BuildContext context, ReaderProvider provider) {
    provider.stopAutoPage();
    Navigator.pop(context);
  }

  void showInterfaceSettings(BuildContext context, ReaderProvider provider) {
    ReaderSettingsSheets.showInterfaceSettings(context, provider);
  }

  void showMoreSettings(BuildContext context, ReaderProvider provider) {
    ReaderSettingsSheets.showMoreSettings(context, provider);
  }

  void showPageTurnModeSettings(BuildContext context, ReaderProvider provider) {
    ReaderSettingsSheets.showPageTurnMode(context, provider);
  }

  Future<void> handleAutoPage(
    BuildContext context,
    ReaderProvider provider,
  ) async {
    if (!provider.isAutoPaging) {
      provider.toggleAutoPage();
      provider.dismissControls();
      return;
    }
    await AutoReadDialog.show(context);
  }

  Future<void> openSearch(BuildContext context, ReaderProvider provider) async {
    provider.dismissControls();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
  }

  Future<void> openReplaceRule(
    BuildContext context,
    ReaderProvider provider,
  ) async {
    provider.dismissControls();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReplaceRulePage()),
    );
  }

  void showMore(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: '更多操作',
      icon: Icons.more_horiz_rounded,
      children: [
        ListTile(
          leading: const Icon(Icons.rule_rounded),
          title: const Text('內容替換規則'),
          subtitle: const Text('自定義字詞替換與屏蔽'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReplaceRulePage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings_suggest_rounded),
          title: const Text('全域系統設定'),
          subtitle: const Text('備份、還原與解析引擎配置'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }

  void _dispatchTapZoneAction(
    ReaderProvider provider, {
    required Offset position,
    required Size viewportSize,
  }) {
    final action = _resolveTapAction(
      provider,
      position: position,
      viewportSize: viewportSize,
    );
    switch (action) {
      case ReaderTapAction.menu:
        provider.toggleControls();
        return;
      case ReaderTapAction.nextPage:
        provider.nextPage();
        return;
      case ReaderTapAction.prevPage:
        provider.prevPage();
        return;
      case ReaderTapAction.nextChapter:
        unawaited(provider.nextChapter());
        return;
      case ReaderTapAction.prevChapter:
        unawaited(provider.prevChapter(fromEnd: false));
        return;
      case ReaderTapAction.toggleTts:
        provider.toggleTts();
        return;
      case ReaderTapAction.bookmark:
        unawaited(provider.toggleBookmark());
        return;
    }
  }

  ReaderTapAction _resolveTapAction(
    ReaderProvider provider, {
    required Offset position,
    required Size viewportSize,
  }) {
    final zoneIndex = _resolveTapZoneIndex(
      position: position,
      viewportSize: viewportSize,
    );
    return ReaderTapAction.fromCode(provider.clickActions[zoneIndex]);
  }

  int _resolveTapZoneIndex({
    required Offset position,
    required Size viewportSize,
  }) {
    final row = (position.dy / (viewportSize.height / 3)).floor().clamp(0, 2);
    final col = (position.dx / (viewportSize.width / 3)).floor().clamp(0, 2);
    return row * 3 + col;
  }
}

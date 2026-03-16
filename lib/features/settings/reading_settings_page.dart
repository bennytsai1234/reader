import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class ReadingSettingsPage extends StatelessWidget {
  const ReadingSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('閱讀設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              ListTile(
                title: const Text('螢幕方向'),
                subtitle: const Text('跟隨系統 / 橫向 / 直向'),
                leading: const Icon(Icons.screen_rotation),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('螢幕常亮時間'),
                subtitle: const Text('設定閱讀時螢幕多久後休眠'),
                leading: const Icon(Icons.timer_outlined),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('隱藏狀態欄'),
                value: settings.hideStatusBar,
                onChanged: (v) => settings.setHideStatusBar(v),
              ),
              SwitchListTile(
                title: const Text('隱藏導航欄'),
                value: settings.hideNavigationBar,
                onChanged: (v) => settings.setHideNavigationBar(v),
              ),
              SwitchListTile(
                title: const Text('正文支援連字 (Ligature)'),
                value: settings.readBodyToLh,
                onChanged: (v) => settings.setReadBodyToLh(v),
              ),
              SwitchListTile(
                title: const Text('適配挖孔螢幕 (留出邊距)'),
                value: settings.paddingDisplayCutouts,
                onChanged: (v) => settings.setPaddingDisplayCutouts(v),
              ),
              ListTile(
                title: const Text('橫向雙頁顯示'),
                subtitle: const Text('平板或橫螢幕狀態下的雙頁排版'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('進度條行為'),
                subtitle: const Text('按章節進度或按全書百分比顯示'),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('使用中文獨立排版'),
                subtitle: const Text('強迫套用中文排版規則'),
                value: settings.useZhLayout,
                onChanged: (v) => settings.setUseZhLayout(v),
              ),
              SwitchListTile(
                title: const Text('文字兩端對齊'),
                value: settings.textFullJustify,
                onChanged: (v) => settings.setTextFullJustify(v),
              ),
              SwitchListTile(
                title: const Text('文字底部對齊'),
                value: settings.textBottomJustify,
                onChanged: (v) => settings.setTextBottomJustify(v),
              ),
              SwitchListTile(
                title: const Text('滑鼠滾輪翻頁'),
                value: settings.mouseWheelPage,
                onChanged: (v) => settings.setMouseWheelPage(v),
              ),
              SwitchListTile(
                title: const Text('音量鍵翻頁'),
                value: settings.volumeKeyPage,
                onChanged: (v) => settings.setVolumeKeyPage(v),
              ),
              SwitchListTile(
                title: const Text('播放音訊時使用音量鍵翻頁'),
                value: settings.volumeKeyPageOnPlay,
                onChanged: (v) => settings.setVolumeKeyPageOnPlay(v),
              ),
              SwitchListTile(
                title: const Text('長按翻頁'),
                value: settings.keyPageOnLongPress,
                onChanged: (v) => settings.setKeyPageOnLongPress(v),
              ),
              ListTile(
                title: const Text('翻頁觸控滑動距離 (Slop)'),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('自動替換書源 (來源失效時)'),
                value: settings.autoChangeSource,
                onChanged: (v) => settings.setAutoChangeSource(v),
              ),
              SwitchListTile(
                title: const Text('可長按選取文字'),
                value: settings.selectText,
                onChanged: (v) => settings.setSelectText(v),
              ),
              SwitchListTile(
                title: const Text('顯示亮度調節面板'),
                value: settings.showBrightnessView,
                onChanged: (v) => settings.setShowBrightnessView(v),
              ),
              SwitchListTile(
                title: const Text('關閉點擊翻頁動畫 (無動畫翻頁)'),
                value: settings.noAnimScrollPage,
                onChanged: (v) => settings.setNoAnimScrollPage(v),
              ),
              SwitchListTile(
                title: const Text('點擊預覽圖片'),
                value: settings.previewImageByClick,
                onChanged: (v) => settings.setPreviewImageByClick(v),
              ),
              SwitchListTile(
                title: const Text('啟動渲染最佳化'),
                value: settings.optimizeRender,
                onChanged: (v) => settings.setOptimizeRender(v),
              ),
              ListTile(
                title: const Text('點擊區域設定 (打點區)'),
                subtitle: const Text('自訂螢幕各點擊區塊的對應行為'),
                leading: const Icon(Icons.touch_app),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('停用返回鍵'),
                value: settings.disableReturnKey,
                onChanged: (v) => settings.setDisableReturnKey(v),
              ),
              ListTile(
                title: const Text('自訂實體翻頁按鍵'),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('展開文字選單'),
                value: settings.expandTextMenu,
                onChanged: (v) => settings.setExpandTextMenu(v),
              ),
              SwitchListTile(
                title: const Text('標題與副標題附加顯示'),
                value: settings.showReadTitleAddition,
                onChanged: (v) => settings.setShowReadTitleAddition(v),
              ),
              SwitchListTile(
                title: const Text('底部欄跟隨頁面模式'),
                value: settings.readBarStyleFollowPage,
                onChanged: (v) => settings.setReadBarStyleFollowPage(v),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('功能開發中 (Work in Progress)')),
    );
  }
}


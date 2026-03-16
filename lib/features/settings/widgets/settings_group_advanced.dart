import 'package:flutter/material.dart';
import '../settings_provider.dart';

class SettingsGroupAdvanced extends StatelessWidget {
  final SettingsProvider settings;
  final Function(BuildContext) showComingSoon;

  const SettingsGroupAdvanced({super.key, required this.settings, required this.showComingSoon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('進階與實驗性'),
        SwitchListTile(
          title: const Text('啟用 Cronet'),
          subtitle: const Text('使用 Chromium 網路堆疊 (實驗性)'),
          value: settings.enableCronet,
          onChanged: (v) => settings.setEnableCronet(v),
        ),
        SwitchListTile(
          title: const Text('圖片抗鋸齒'),
          value: settings.antiAlias,
          onChanged: (v) => settings.setAntiAlias(v),
        ),
        SwitchListTile(
          title: const Text('預設啟用替換規則'),
          value: settings.replaceEnableDefault,
          onChanged: (v) => settings.setReplaceEnableDefault(v),
        ),
        SwitchListTile(
          title: const Text('退出時暫停媒體按鍵'),
          value: settings.mediaButtonOnExit,
          onChanged: (v) => settings.setMediaButtonOnExit(v),
        ),
        SwitchListTile(
          title: const Text('媒體鍵朗讀'),
          value: settings.readAloudByMediaButton,
          onChanged: (v) => settings.setReadAloudByMediaButton(v),
        ),
        SwitchListTile(
          title: const Text('顯示加入書架提示'),
          value: settings.showAddToShelfAlert,
          onChanged: (v) => settings.setShowAddToShelfAlert(v),
        ),
        SwitchListTile(
          title: const Text('顯示漫畫 UI'),
          value: settings.showMangaUi,
          onChanged: (v) => settings.setShowMangaUi(v),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }
}


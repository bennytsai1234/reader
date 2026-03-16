import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../settings_provider.dart';

class SettingsGroupSystem extends StatelessWidget {
  final SettingsProvider settings;
  final Function(BuildContext) showComingSoon;
  final Function(BuildContext, SettingsProvider) showThreadCountDialog;

  const SettingsGroupSystem({super.key, required this.settings, required this.showComingSoon, required this.showThreadCountDialog});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('系統與資料管理'),
        SwitchListTile(
          title: const Text('Web 服務保留喚醒鎖'),
          value: settings.webServiceWakeLock,
          onChanged: (v) => settings.setWebServiceWakeLock(v),
        ),
        ListTile(
          title: const Text('書籍存放目錄'),
          subtitle: Text(settings.bookStorageDir.isEmpty ? '預設 (文件目錄)' : settings.bookStorageDir),
          onTap: () async {
            final result = await FilePicker.platform.getDirectoryPath();
            if (result != null) settings.setBookStorageDir(result);
          },
        ),
        SwitchListTile(
          title: const Text('忽略音訊焦點'),
          value: settings.ignoreAudioFocus,
          onChanged: (v) => settings.setIgnoreAudioFocus(v),
        ),
        SwitchListTile(
          title: const Text('自動清理過期數據'),
          value: settings.autoClearExpired,
          onChanged: (v) => settings.setAutoClearExpired(v),
        ),
        ListTile(
          title: const Text('執行緒數量'),
          subtitle: Text('${settings.threadCount} (併發請求數量)'),
          onTap: () => showThreadCountDialog(context, settings),
        ),
        SwitchListTile(
          title: const Text('記錄除錯日誌 (Log)'),
          value: settings.recordLog,
          onChanged: (v) => settings.setRecordLog(v),
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


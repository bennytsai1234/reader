import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

import 'click_action_config_page.dart';

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
              _buildSectionTitle('操作'),
              ListTile(
                title: const Text('點擊區域設定 (打點區)'),
                subtitle: const Text('自訂螢幕各點擊區塊的對應行為'),
                leading: const Icon(Icons.touch_app),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClickActionConfigPage(),
                      ),
                    ),
              ),

              const Divider(),
              _buildSectionTitle('排版'),
              SwitchListTile(
                title: const Text('文字兩端對齊'),
                value: settings.textFullJustify,
                onChanged: (v) => settings.setTextFullJustify(v),
              ),

              const Divider(),
              _buildSectionTitle('內容'),
              SwitchListTile(
                title: const Text('自動替換書源 (來源失效時)'),
                value: settings.autoChangeSource,
                onChanged: (v) => settings.setAutoChangeSource(v),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

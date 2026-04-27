import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_provider.dart';
import 'welcome_settings_page.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外觀與主題')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionTitle('主介面'),
              ListTile(
                title: const Text('歡迎介面'),
                subtitle: const Text('設定 App 啟動時的歡迎圖片'),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WelcomeSettingsPage(),
                      ),
                    ),
              ),
              const Divider(),
              _buildSectionTitle('主題'),
              _buildThemeModeTile(context, settings),
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

  Widget _buildThemeModeTile(BuildContext context, SettingsProvider settings) {
    final modes = ['跟隨系統', '白天模式', '夜間模式'];
    final currentMode =
        settings.themeMode == ThemeMode.system
            ? 0
            : (settings.themeMode == ThemeMode.light ? 1 : 2);

    return ListTile(
      title: const Text('主題模式'),
      subtitle: Text(modes[currentMode]),
      onTap: () {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('主題模式'),
                content: RadioGroup<int>(
                  groupValue: currentMode,
                  onChanged: (val) {
                    if (val == null) return;
                    final mode =
                        val == 0
                            ? ThemeMode.system
                            : (val == 1 ? ThemeMode.light : ThemeMode.dark);
                    settings.setThemeMode(mode);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      return RadioListTile<int>(
                        title: Text(modes[index]),
                        value: index,
                        // ignore: deprecated_member_use
                        groupValue: null,
                        // ignore: deprecated_member_use
                        onChanged: null,
                      );
                    }),
                  ),
                ),
              ),
        );
      },
    );
  }
}

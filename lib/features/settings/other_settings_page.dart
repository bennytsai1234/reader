import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/cache_manager/storage_management_page.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class OtherSettingsPage extends StatelessWidget {
  const OtherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('其他設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionTitle('區域與環境'),
              ListTile(
                title: const Text('語言 (Language)'),
                subtitle: Text(_getLanguageName(settings.locale)),
                leading: const Icon(Icons.language),
                onTap: () => _showLanguageDialog(context, settings),
              ),
              const Divider(),

              _buildSectionTitle('存儲與數據'),
              ListTile(
                title: const Text('存儲與下載'),
                subtitle: const Text('管理下載任務、清理快取空間'),
                leading: const Icon(Icons.storage_outlined),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StorageManagementPage(),
                      ),
                    ),
              ),
              const Divider(),

              _buildSectionTitle('閱讀行為'),
              SwitchListTile(
                title: const Text('預設啟用替換規則'),
                value: settings.replaceEnableDefault,
                onChanged: (v) => settings.setReplaceEnableDefault(v),
              ),
              SwitchListTile(
                title: const Text('顯示加入書架提示'),
                value: settings.showAddToShelfAlert,
                onChanged: (v) => settings.setShowAddToShelfAlert(v),
              ),
              const SizedBox(height: 24),
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

  String _getLanguageName(Locale? locale) {
    if (locale == null) return '跟隨系統';
    final code = locale.languageCode;
    if (code == 'zh') {
      return (locale.countryCode == 'TW' || locale.countryCode == 'HK')
          ? '繁體中文'
          : '简体中文';
    }
    return code == 'en' ? 'English' : locale.toString();
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
    final languages = [
      {'label': '跟隨系統', 'value': 'system'},
      {'label': '繁體中文', 'value': 'zh_TW'},
      {'label': '简体中文', 'value': 'zh_CN'},
      {'label': 'English', 'value': 'en'},
    ];
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('選擇語言'),
            content: RadioGroup<String>(
              groupValue:
                  settings.locale == null
                      ? 'system'
                      : (languages.any(
                            (l) =>
                                l['value'] ==
                                '${settings.locale!.languageCode}_${settings.locale!.countryCode}',
                          )
                          ? '${settings.locale!.languageCode}_${settings.locale!.countryCode}'
                          : settings.locale!.languageCode),
              onChanged: (val) {
                if (val != null) {
                  settings.setLanguage(val);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    languages
                        .map(
                          (lang) => RadioListTile<String>(
                            title: Text(lang['label']!),
                            value: lang['value']!,
                            // ignore: deprecated_member_use
                            groupValue: null,
                            // ignore: deprecated_member_use
                            onChanged: null,
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
    );
  }
}

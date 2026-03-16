import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'welcome_settings_page.dart';
import 'icon_settings_page.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主題設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              // 1. 更換圖標
              ListTile(
                title: const Text('更換圖標'),
                subtitle: const Text('更換桌面圖標'),
                leading: const Icon(Icons.app_shortcut),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IconSettingsPage()),
                  );
                },
              ),
              // 2. 歡迎介面
              ListTile(
                title: const Text('歡迎介面'),
                subtitle: const Text('設定歡迎介面圖片與樣式'),
                leading: const Icon(Icons.waving_hand_outlined),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeSettingsPage()),
                  );
                },
              ),
              // 3. 沉浸式狀態欄
              SwitchListTile(
                title: const Text('沉浸式狀態欄'),
                subtitle: const Text('關閉可解決部分挖孔螢幕遮擋問題'),
                value: settings.transparentStatusBar,
                onChanged: (v) => settings.setTransparentStatusBar(v),
              ),
              // 4. 沉浸式導覽列
              SwitchListTile(
                title: const Text('沉浸式導覽列'),
                subtitle: const Text('讓底部導覽列背景透明'),
                value: settings.immNavigationBar,
                onChanged: (v) => settings.setImmNavigationBar(v),
              ),
              // 5. 標題與底部欄高度
              ListTile(
                title: const Text('標題與底部欄高度'),
                subtitle: const Text('調整標題欄與底部欄的視覺高度'),
                leading: const Icon(Icons.height),
                onTap: () => _showComingSoon(context),
              ),
              // 6. 字體大小
              ListTile(
                title: const Text('字體大小'),
                subtitle: const Text('App 全局字體大小縮放比例'),
                leading: const Icon(Icons.format_size),
                onTap: () => _showComingSoon(context),
              ),
              // 7. 封面設定
              ListTile(
                title: const Text('封面設定'),
                subtitle: const Text('修改預設書本封面及樣式'),
                leading: const Icon(Icons.book_outlined),
                onTap: () => _showComingSoon(context),
              ),
              // 8. 自訂主題列表
              ListTile(
                title: const Text('主題列表'),
                subtitle: const Text('管理所有自訂主題設定檔'),
                leading: const Icon(Icons.list_alt),
                onTap: () => _showComingSoon(context),
              ),

              const Divider(),
              _buildSectionTitle('日間主題'),
              _buildColorTile(context, '主色調', settings.dayPrimaryColor, (c) => settings.setDayPrimaryColor(c)),
              _buildColorTile(context, '強調色', settings.dayAccentColor, (c) => settings.setDayAccentColor(c)),
              _buildColorTile(context, '背景色', settings.dayBackgroundColor, (c) => settings.setDayBackgroundColor(c)),
              _buildColorTile(context, '底部背景色', settings.dayBottomBackgroundColor, (c) => settings.setDayBottomBackgroundColor(c)),
              ListTile(
                title: const Text('背景圖片'),
                leading: const Icon(Icons.image_outlined),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('儲存主題設定'),
                subtitle: const Text('將目前日間配色儲存為獨立主題'),
                leading: const Icon(Icons.save_outlined),
                onTap: () => _showComingSoon(context),
              ),

              const Divider(),
              _buildSectionTitle('夜間主題'),
              _buildColorTile(context, '主色調', settings.nightPrimaryColor, (c) => settings.setNightPrimaryColor(c)),
              _buildColorTile(context, '強調色', settings.nightAccentColor, (c) => settings.setNightAccentColor(c)),
              _buildColorTile(context, '背景色', settings.nightBackgroundColor, (c) => settings.setNightBackgroundColor(c)),
              _buildColorTile(context, '底部背景色', settings.nightBottomBackgroundColor, (c) => settings.setNightBottomBackgroundColor(c)),
              ListTile(
                title: const Text('背景圖片'),
                leading: const Icon(Icons.image_outlined),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('儲存主題設定'),
                subtitle: const Text('將目前夜間配色儲存為獨立主題'),
                leading: const Icon(Icons.save_outlined),
                onTap: () => _showComingSoon(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildColorTile(BuildContext context, String title, Color currentColor, Function(Color) onColorChanged) {
    return ListTile(
      title: Text(title),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
      ),
      onTap: () => _showColorPicker(context, title, currentColor, onColorChanged),
    );
  }

  void _showColorPicker(BuildContext context, String title, Color currentColor, Function(Color) onColorChanged) {
    final colors = [
      Colors.brown, Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan, Colors.teal,
      Colors.green, Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber,
      Colors.orange, Colors.deepOrange, Colors.grey, Colors.blueGrey, Colors.black,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('選擇 $title'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  onColorChanged(colors[index]);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentColor == colors[index] ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (currentColor == colors[index])
                        const BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('功能開發中 (Work in Progress)')),
    );
  }
}


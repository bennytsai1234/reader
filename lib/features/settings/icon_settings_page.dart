import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class IconSettingsPage extends StatelessWidget {
  const IconSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final icons = [
      {'id': 'Launcher1', 'name': '預設圖標', 'color': Colors.blue},
      {'id': 'Launcher2', 'name': '簡約黑', 'color': Colors.black},
      {'id': 'Launcher3', 'name': '活力紅', 'color': Colors.red},
      {'id': 'Launcher4', 'name': '清新綠', 'color': Colors.green},
      {'id': 'Launcher5', 'name': '優雅紫', 'color': Colors.purple},
      {'id': 'Launcher6', 'name': '暖陽橘', 'color': Colors.orange},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('更換圖標')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final icon = icons[index];
              final isSelected = settings.launcherIcon == icon['id'] || (settings.launcherIcon.isEmpty && index == 0);
              
              return InkWell(
                onTap: () => settings.setLauncherIcon(icon['id'] as String),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: (icon['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.library_books, 
                            size: 40, 
                            color: icon['color'] as Color
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      icon['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '註：變更圖標在部分平台上可能需要重新啟動 App 才能生效。',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}


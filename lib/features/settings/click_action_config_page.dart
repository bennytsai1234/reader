import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class ClickActionConfigPage extends StatelessWidget {
  const ClickActionConfigPage({super.key});

  static const Map<int, String> _actionNames = {
    0: '喚起選單',
    1: '下一頁',
    2: '上一頁',
    3: '下一章',
    4: '上一章',
    5: '朗讀',
    7: '書籤',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('點擊區域設置'),
        actions: [
          TextButton(
            onPressed: () {
              // 恢復預設邏輯 (暫略)
            },
            child: const Text('恢復預設', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          // 注意：這裡假設 SettingsProvider 已實作了 clickActions 的讀取與保存
          // 目前先用本地模擬數據演示 UI，後續接入 Provider
          final actions = [2, 1, 1, 2, 0, 1, 2, 1, 1]; 

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('點擊下方區域進行功能映射配置', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 9,
                    itemBuilder: (ctx, index) {
                      return InkWell(
                        onTap: () => _showActionSelector(context, index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('區域 ${index + 1}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                                const SizedBox(height: 8),
                                Text(
                                  _actionNames[actions[index]] ?? '無功能',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showActionSelector(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _actionNames.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              onTap: () {
                // 保存邏輯
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

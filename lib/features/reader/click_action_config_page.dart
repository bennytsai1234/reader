import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';

class ClickActionConfigPage extends StatelessWidget {
  const ClickActionConfigPage({super.key});

  static const Map<int, String> actions = {
    0: '喚起選單',
    1: '下一頁',
    2: '上一頁',
    3: '下一章',
    4: '上一章',
    7: '加入書籤',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('點擊區域設定')),
      body: Consumer<ReaderProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('點擊下方九宮格區域進行自定義功能映射', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final action = provider.clickActions[index];
                      return GestureDetector(
                        onTap: () => _showActionPicker(context, provider, index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              actions[action] ?? '未知',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('小提示：通常正中央建議設定為「喚起選單」', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showActionPicker(BuildContext context, ReaderProvider provider, int gridIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: actions.entries.map((e) {
            return ListTile(
              title: Text(e.value),
              trailing: provider.clickActions[gridIndex] == e.key ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                provider.setClickAction(gridIndex, e.key);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}


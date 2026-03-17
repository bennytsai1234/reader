import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'setting_components.dart';

class AdvancedSettingSheet extends StatelessWidget {
  const AdvancedSettingSheet({super.key});

  static const Map<int, String> actionNames = {
    -1: '無動作', 0: '開啟選單', 1: '下一頁', 2: '上一頁', 3: '下一章', 4: '上一章', 5: '朗讀 (TTS)', 6: '自動翻頁', 7: '加入書籤', 8: '切換主題', 9: '增加亮度', 10: '減少亮度',
  };

  static void show(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ChangeNotifierProvider.value(
          value: provider,
          child: const AdvancedSettingSheet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, sc) => SingleChildScrollView(
        controller: sc,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('系統設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            const Text('內容處理', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                SettingComponents.buildChoiceChip(label: '原樣', value: 0, groupValue: provider.chineseConvert, onSelected: provider.setChineseConvert),
                SettingComponents.buildChoiceChip(label: '簡轉繁', value: 1, groupValue: provider.chineseConvert, onSelected: provider.setChineseConvert),
                SettingComponents.buildChoiceChip(label: '繁轉簡', value: 2, groupValue: provider.chineseConvert, onSelected: provider.setChineseConvert),
              ],
            ),
            const Divider(height: 32),

            const Text('九宮格動作自定義', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final code = provider.clickActions[index];
                return InkWell(
                  onTap: () => _showPicker(context, provider, index),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.withValues(alpha: 0.05),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('區域 ${index + 1}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(actionNames[code] ?? '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.cloud_sync, color: Colors.blue),
                title: const Text('手動同步到 WebDAV', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                onTap: () { provider.syncWebDAV(); Navigator.pop(context); },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, ReaderProvider provider, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('選擇動作'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: actionNames.entries.map((e) => ListTile(
              title: Text(e.value),
              onTap: () { provider.setClickAction(index, e.key); Navigator.pop(ctx); },
            )).toList(),
          ),
        ),
      ),
    );
  }
}


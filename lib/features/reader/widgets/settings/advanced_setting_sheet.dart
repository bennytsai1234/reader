import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'setting_components.dart';

class AdvancedSettingSheet extends StatelessWidget {
  const AdvancedSettingSheet({super.key});

  static const Map<int, String> actionNames = {
    0: '開啟選單', 1: '下一頁', 2: '上一頁', 3: '下一章', 4: '上一章', 5: '朗讀 (TTS)', 6: '自動翻頁', 7: '加入書籤',
  };

  static void show(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: const AdvancedSettingSheet(),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('系統設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            const Text('內容處理', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Wrap(
              spacing: 8,
              children: [
                SettingComponents.buildChoiceChip(label: '原樣', value: 0, groupValue: provider.chineseConvert, onSelected: provider.setChineseConvert),
                SettingComponents.buildChoiceChip(label: '簡轉繁', value: 1, groupValue: provider.chineseConvert, onSelected: provider.setChineseConvert),
                SettingComponents.buildChoiceChip(label: '繁轉簡', value: 2, groupValue: provider.chineseConvert, onSelected: provider.setChineseConvert),
              ],
            ),
            const Divider(height: 32),

            const Text('TTS 朗讀引擎', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Row(
              children: [
                SettingComponents.buildChoiceChip(label: '系統語音', value: 0, groupValue: provider.ttsMode, onSelected: provider.setTtsMode),
                const SizedBox(width: 8),
                SettingComponents.buildChoiceChip(label: '網絡語音', value: 1, groupValue: provider.ttsMode, onSelected: provider.setTtsMode),
              ],
            ),
            SettingComponents.buildSliderRow(label: '語速', value: provider.rate, min: 0.5, max: 2.0, onChanged: provider.setTtsRate),
            const Divider(height: 32),

            const Text('九宮格動作自定義', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.2,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: 9,
                itemBuilder: (context, index) {
                  final code = provider.clickActions[index];
                  return InkWell(
                    onTap: () => _showPicker(context, provider, index),
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                      child: Center(child: Text(actionNames[code] ?? '-', style: const TextStyle(fontSize: 10))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('手動同步到 WebDAV'),
              onTap: () { provider.syncWebDAV(); Navigator.pop(context); },
            ),
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


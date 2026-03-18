import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

class AdvancedSettingSheet extends StatelessWidget {
  const AdvancedSettingSheet({super.key});

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
    final theme = provider.currentTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('進階設定', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textColor)),
            const SizedBox(height: 20),

            Text('繁簡轉換', style: TextStyle(fontSize: 14, color: theme.textColor.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildChip(context, provider, label: '不轉換', value: 0),
                _buildChip(context, provider, label: '簡轉繁', value: 1),
                _buildChip(context, provider, label: '繁轉簡', value: 2),
              ],
            ),
            const Divider(height: 32),

            Text('備註：WebDAV 與 狀態列切換功能目前由系統全域設定接管。',
                style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, ReaderProvider provider, {required String label, required int value}) {
    final isSelected = provider.chineseConvert == value;
    final theme = provider.currentTheme;
    
    // 選中狀態下的背景色採用主題文字色
    final Color activeBgColor = theme.textColor;
    // 根據背景色亮度計算最清晰的文字顏色（黑或白），不再依賴主題背景色
    final Color activeTextColor = activeBgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? activeTextColor : theme.textColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      selectedColor: activeBgColor,
      backgroundColor: theme.textColor.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? activeBgColor : theme.textColor.withValues(alpha: 0.2),
        width: 1,
      ),
      onSelected: (_) => provider.setChineseConvert(value),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';

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

  static const Map<int, String> _clickActions = {
    0: '喚起選單',
    1: '下一頁',
    2: '上一頁',
    3: '下一章',
    4: '上一章',
    7: '加入書籤',
  };

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

            // 九宮格點擊區域設定（對標 Android clickAction 九宮格）
            Text('點擊區域設定', style: TextStyle(fontSize: 14, color: theme.textColor.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Text('自定義螢幕各區域的點擊功能', style: TextStyle(fontSize: 11, color: theme.textColor.withValues(alpha: 0.35))),
            const SizedBox(height: 12),
            _buildClickActionGrid(context, provider),
            const Divider(height: 32),

            Text('備註：WebDAV 與 狀態列切換功能目前由系統全域設定接管。',
                style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 九宮格點擊區域設定 UI
  Widget _buildClickActionGrid(BuildContext context, ReaderProvider provider) {
    final theme = provider.currentTheme;
    final isLight = theme.backgroundColor.computeLuminance() > 0.5;
    final borderColor = theme.textColor.withValues(alpha: 0.2);
    final cellBg = theme.textColor.withValues(alpha: isLight ? 0.06 : 0.1);

    return AspectRatio(
      aspectRatio: 3 / 2.2, // 稍扁的九宮格，不會撐太高
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final action = provider.clickActions[index];
          final label = _clickActions[action] ?? '未知';
          return GestureDetector(
            onTap: () => _showActionPicker(context, provider, index),
            child: Container(
              decoration: BoxDecoration(
                color: cellBg,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: theme.textColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActionPicker(BuildContext context, ReaderProvider provider, int gridIndex) {
    final theme = provider.currentTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.backgroundColor,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: _clickActions.entries.map((e) {
            final isSelected = provider.clickActions[gridIndex] == e.key;
            return ListTile(
              title: Text(e.value, style: TextStyle(color: theme.textColor)),
              trailing: isSelected ? Icon(Icons.check, color: theme.textColor) : null,
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

  Widget _buildChip(BuildContext context, ReaderProvider provider, {required String label, required int value}) {
    final isSelected = provider.chineseConvert == value;
    final theme = provider.currentTheme;

    final Color activeBgColor = theme.textColor;
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

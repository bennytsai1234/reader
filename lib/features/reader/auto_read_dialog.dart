import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'widgets/reader_settings_sheets.dart';
import 'package:legado_reader/core/constant/page_anim.dart';


class AutoReadDialog extends StatelessWidget {
  const AutoReadDialog({super.key});

  /// 顯示自動翻頁對話框，返回 Future 以便呼叫方感知關閉事件
  static Future<void> show(BuildContext context) async {
    final readerProvider = context.read<ReaderProvider>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(
        value: readerProvider,
        child: const AutoReadDialog(),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題列
          Row(
            children: [
              Icon(Icons.autorenew, color: theme.textColor, size: 18),
              const SizedBox(width: 8),
              Text('自動翻頁', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              // 暫停/繼續按鈕
              if (provider.isAutoPagePaused)
                GestureDetector(
                  onTap: () => provider.resumeAutoPage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.play_arrow, color: theme.textColor, size: 14),
                      const SizedBox(width: 4),
                      Text('繼續', style: TextStyle(color: theme.textColor, fontSize: 12)),
                    ]),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => provider.pauseAutoPage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.pause, color: theme.textColor, size: 14),
                      const SizedBox(width: 4),
                      Text('暫停', style: TextStyle(color: theme.textColor, fontSize: 12)),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 速度滑桿
          Row(
            children: [
              Text('翻頁速度', style: TextStyle(color: theme.textColor.withValues(alpha: 0.7), fontSize: 13)),
              const Spacer(),
              Text('${provider.autoPageSpeed.toInt()} 秒/頁', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: provider.autoPageSpeed.clamp(5.0, 300.0),
            min: 5.0,
            max: 300.0,
            divisions: 59,
            activeColor: theme.textColor.withValues(alpha: 0.7),
            inactiveColor: theme.textColor.withValues(alpha: 0.15),
            onChanged: (v) => provider.setAutoPageSpeed(v),
          ),
          const SizedBox(height: 8),

          // 翻頁模式快捷切換
          Row(
            children: [
              Text('翻頁模式', style: TextStyle(color: theme.textColor.withValues(alpha: 0.7), fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(child: _buildPageModeSelector(context, provider)),
            ],
          ),
          const SizedBox(height: 16),

          // 功能按鈕列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAction(
                context,
                icon: Icons.menu,
                label: '主選單',
                onTap: () {
                  Navigator.pop(context);
                  provider.toggleControls();
                },
              ),
              _buildAction(
                context,
                icon: Icons.list,
                label: '目錄',
                onTap: () {
                  Navigator.pop(context);
                  Scaffold.of(context).openDrawer();
                },
              ),
              _buildAction(
                context,
                icon: Icons.stop_circle_outlined,
                label: '停止',
                onTap: () {
                  provider.stopAutoPage();
                  Navigator.pop(context);
                },
              ),
              _buildAction(
                context,
                icon: Icons.settings,
                label: '設定',
                onTap: () {
                  Navigator.pop(context);
                  ReaderSettingsSheets.showPageTurnMode(context, provider);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 翻頁模式選擇器（平移 vs 捲動）
  Widget _buildPageModeSelector(BuildContext context, ReaderProvider provider) {
    final theme = provider.currentTheme;
    const modes = [
      (PageAnim.slide, '平移'),
      (PageAnim.scroll, '捲動'),
    ];

    return Row(
      children: modes.map((mode) {
        final isSelected = provider.pageTurnMode == mode.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              provider.setPageTurnMode(mode.$1);
              // 切換模式後重啟自動翻頁計時器
              if (provider.isAutoPaging) {
                provider.setAutoPageSpeed(provider.autoPageSpeed);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.textColor.withValues(alpha: 0.15)
                    : theme.textColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: isSelected
                    ? Border.all(color: theme.textColor.withValues(alpha: 0.4), width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  mode.$2,
                  style: TextStyle(
                    color: isSelected ? theme.textColor : theme.textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAction(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = context.read<ReaderProvider>().currentTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.textColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: theme.textColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

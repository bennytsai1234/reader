import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_page_action_dispatcher.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'widgets/reader/reader_menu_palette.dart';

class AutoReadDialog extends StatelessWidget {
  const AutoReadDialog({super.key});
  static const ReaderPageActionDispatcher _actionDispatcher =
      ReaderPageActionDispatcher();

  /// 顯示自動翻頁對話框，返回 Future 以便呼叫方感知關閉事件
  static Future<void> show(BuildContext context) async {
    final readerProvider = context.read<ReaderProvider>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ChangeNotifierProvider.value(
            value: readerProvider,
            child: const AutoReadDialog(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: ReaderMenuPalette.background,
        border: Border(top: BorderSide(color: ReaderMenuPalette.outline)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題列
          Row(
            children: [
              const Icon(
                Icons.autorenew,
                color: ReaderMenuPalette.foreground,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                '自動翻頁',
                style: TextStyle(
                  color: ReaderMenuPalette.foreground,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              // 暫停/繼續按鈕
              if (provider.isAutoPagePaused)
                GestureDetector(
                  onTap: () => provider.resumeAutoPage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ReaderMenuPalette.backgroundElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: ReaderMenuPalette.foreground,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '繼續',
                          style: TextStyle(
                            color: ReaderMenuPalette.foreground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => provider.pauseAutoPage(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ReaderMenuPalette.backgroundElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.pause,
                          color: ReaderMenuPalette.foreground,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '暫停',
                          style: TextStyle(
                            color: ReaderMenuPalette.foreground,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 速度滑桿
          Row(
            children: [
              const Text(
                '翻頁速度',
                style: TextStyle(
                  color: ReaderMenuPalette.mutedForeground,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${provider.autoPageSpeed.toInt()} 秒/頁',
                style: const TextStyle(
                  color: ReaderMenuPalette.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SpeedPreset(seconds: 10),
              _SpeedPreset(seconds: 15),
              _SpeedPreset(seconds: 20),
              _SpeedPreset(seconds: 30),
              _SpeedPreset(seconds: 45),
              _SpeedPreset(seconds: 60),
            ],
          ),
          Slider(
            value: provider.autoPageSpeed.clamp(1.0, 120.0),
            min: 1.0,
            max: 120.0,
            divisions: 119,
            activeColor: ReaderMenuPalette.accent,
            inactiveColor: ReaderMenuPalette.mutedForeground.withValues(
              alpha: 0.15,
            ),
            onChanged: (v) => provider.setAutoPageSpeed(v),
          ),
          const SizedBox(height: 8),

          // 翻頁模式快捷切換
          Row(
            children: [
              const Text(
                '翻頁模式',
                style: TextStyle(
                  color: ReaderMenuPalette.mutedForeground,
                  fontSize: 13,
                ),
              ),
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
                onTap:
                    () => _actionDispatcher.openMainMenuFromAutoReadDialog(
                      context,
                      provider,
                    ),
              ),
              _buildAction(
                context,
                icon: Icons.list,
                label: '目錄',
                onTap:
                    () =>
                        _actionDispatcher.openDrawerFromAutoReadDialog(context),
              ),
              _buildAction(
                context,
                icon: Icons.stop_circle_outlined,
                label: '停止',
                onTap:
                    () => _actionDispatcher.stopAutoPageFromDialog(
                      context,
                      provider,
                    ),
              ),
              _buildAction(
                context,
                icon: Icons.settings,
                label: '設定',
                onTap: () {
                  Navigator.pop(context);
                  _actionDispatcher.showPageTurnModeSettings(context, provider);
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
    const modes = [(PageAnim.slide, '平移翻頁'), (PageAnim.scroll, '上下滾動')];

    return Row(
      children:
          modes.map((mode) {
            final isSelected = provider.pageTurnMode == mode.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  provider.setPageTurnMode(mode.$1);
                  if (provider.isAutoPaging) {
                    provider.restartAutoPageCycle();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? ReaderMenuPalette.accentMuted
                            : ReaderMenuPalette.backgroundElevated,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        isSelected
                            ? Border.all(
                              color: ReaderMenuPalette.accent,
                              width: 1,
                            )
                            : Border.all(color: ReaderMenuPalette.outline),
                  ),
                  child: Center(
                    child: Text(
                      mode.$2,
                      style: TextStyle(
                        color:
                            isSelected
                                ? ReaderMenuPalette.foreground
                                : ReaderMenuPalette.mutedForeground,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ReaderMenuPalette.foreground),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: ReaderMenuPalette.foreground,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedPreset extends StatelessWidget {
  final int seconds;

  const _SpeedPreset({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();
    final isSelected = provider.autoPageSpeed.round() == seconds;
    return ChoiceChip(
      label: Text('${seconds}s'),
      selected: isSelected,
      selectedColor: ReaderMenuPalette.accentMuted,
      backgroundColor: ReaderMenuPalette.backgroundElevated,
      side: BorderSide(
        color:
            isSelected ? ReaderMenuPalette.accent : ReaderMenuPalette.outline,
      ),
      labelStyle: TextStyle(
        color:
            isSelected
                ? ReaderMenuPalette.foreground
                : ReaderMenuPalette.mutedForeground,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (_) => provider.setAutoPageSpeed(seconds.toDouble()),
    );
  }
}

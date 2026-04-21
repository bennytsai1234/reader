import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/shared/theme/app_theme.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';

import 'setting_components.dart';

class InterfaceSettingSheet extends StatefulWidget {
  const InterfaceSettingSheet({super.key});

  static void show(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => ChangeNotifierProvider.value(
            value: provider,
            child: const InterfaceSettingSheet(),
          ),
    );
  }

  @override
  State<InterfaceSettingSheet> createState() => _InterfaceSettingSheetState();
}

class _InterfaceSettingSheetState extends State<InterfaceSettingSheet> {
  final Map<String, Timer> _debouncers = <String, Timer>{};
  bool _didInitialize = false;
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  double _letterSpacing = 0.0;
  double _paragraphSpacing = 1.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialize) return;
    final provider = context.read<ReaderProvider>();
    _fontSize = provider.fontSize;
    _lineHeight = provider.lineHeight;
    _letterSpacing = provider.letterSpacing;
    _paragraphSpacing = provider.paragraphSpacing;
    _didInitialize = true;
  }

  @override
  void dispose() {
    for (final timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();
    super.dispose();
  }

  void _scheduleCommit(String key, VoidCallback action) {
    _debouncers.remove(key)?.cancel();
    _debouncers[key] = Timer(const Duration(milliseconds: 120), action);
  }

  void _commitNow(String key, VoidCallback action) {
    _debouncers.remove(key)?.cancel();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReaderProvider>();

    return AppBottomSheet(
      title: '界面設定',
      icon: Icons.format_paint_outlined,
      children: [
        const SheetSection(title: '閱讀主題'),
        const SizedBox(height: 4),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: AppTheme.readingThemes.length,
            itemBuilder: (context, index) {
              final theme = AppTheme.readingThemes[index];
              final isSelected = provider.themeIndex == index;
              return GestureDetector(
                onTap: () => provider.setTheme(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withValues(alpha: 0.2),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ]
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SheetSection(title: '排版精修'),
        SettingComponents.buildSliderRow(
          label: '字號',
          value: _fontSize,
          min: 14,
          max: 40,
          onChanged: (value) {
            setState(() {
              _fontSize = value;
            });
            _scheduleCommit('fontSize', () => provider.setFontSize(_fontSize));
          },
          onChangeEnd: (value) {
            _commitNow('fontSize', () => provider.setFontSize(value));
          },
        ),
        SettingComponents.buildSliderRow(
          label: '行高',
          value: _lineHeight,
          min: 1.0,
          max: 3.0,
          onChanged: (value) {
            setState(() {
              _lineHeight = value;
            });
            _scheduleCommit(
              'lineHeight',
              () => provider.setLineHeight(_lineHeight),
            );
          },
          onChangeEnd: (value) {
            _commitNow('lineHeight', () => provider.setLineHeight(value));
          },
        ),
        SettingComponents.buildSliderRow(
          label: '字距',
          value: _letterSpacing,
          min: 0.0,
          max: 4.0,
          onChanged: (value) {
            setState(() {
              _letterSpacing = value;
            });
            _scheduleCommit(
              'letterSpacing',
              () => provider.setLetterSpacing(_letterSpacing),
            );
          },
          onChangeEnd: (value) {
            _commitNow('letterSpacing', () => provider.setLetterSpacing(value));
          },
        ),
        SettingComponents.buildSliderRow(
          label: '段距',
          value: _paragraphSpacing,
          min: 0.0,
          max: 3.0,
          onChanged: (value) {
            setState(() {
              _paragraphSpacing = value;
            });
            _scheduleCommit(
              'paragraphSpacing',
              () => provider.setParagraphSpacing(_paragraphSpacing),
            );
          },
          onChangeEnd: (value) {
            _commitNow(
              'paragraphSpacing',
              () => provider.setParagraphSpacing(value),
            );
          },
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              '內容兩端對齊',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Switch(
              value: provider.textFullJustify,
              onChanged: provider.setTextFullJustify,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text(
              '首行縮排',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            DropdownButton<int>(
              value: provider.textIndent,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items:
                  [0, 1, 2, 4]
                      .map(
                        (i) => DropdownMenuItem(value: i, child: Text('$i 字')),
                      )
                      .toList(),
              onChanged: (value) {
                if (value == null) return;
                provider.setTextIndent(value);
              },
            ),
          ],
        ),

        const SheetSection(title: '翻頁與背景'),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: const Text('平移翻頁'),
              selected: provider.pageTurnMode == PageAnim.slide,
              onSelected:
                  (selected) =>
                      selected
                          ? provider.setPageTurnMode(PageAnim.slide)
                          : null,
            ),
            ChoiceChip(
              label: const Text('上下滾動'),
              selected: provider.pageTurnMode == PageAnim.scroll,
              onSelected:
                  (selected) =>
                      selected
                          ? provider.setPageTurnMode(PageAnim.scroll)
                          : null,
            ),
          ],
        ),

        const SheetSection(title: '閱讀殼層'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('顯示常駐底部資訊'),
          value: provider.showReadTitleAddition,
          onChanged: provider.setShowReadTitleAddition,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('選單配色跟隨閱讀頁'),
          value: provider.readBarStyleFollowPage,
          onChanged: provider.setReadBarStyleFollowPage,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('允許文字選取'),
          value: provider.selectText,
          onChanged: provider.setSelectText,
        ),
      ],
    );
  }
}

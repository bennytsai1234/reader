import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_scroll_item.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/view/widgets/scroll_line_item_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'page_mode_delegate.dart';

class ScrollModeDelegate extends PageModeDelegate {
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Map<String, GlobalKey> itemKeys;
  final bool Function() isUserScrolling;

  const ScrollModeDelegate({
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.itemKeys,
    required this.isUserScrolling,
  });

  @override
  Widget build({
    required BuildContext context,
    required ReaderProvider provider,
    required PageController pageController,
    GestureTapUpCallback? onContentTapUp,
  }) {
    final contentStyle = TextStyle(
      fontSize: provider.fontSize,
      height: provider.lineHeight,
      color: provider.currentTheme.textColor,
      letterSpacing: provider.letterSpacing,
    );
    final titleStyle = TextStyle(
      fontSize: provider.fontSize + 4,
      fontWeight: FontWeight.bold,
      color: provider.currentTheme.textColor,
      letterSpacing: provider.letterSpacing,
    );
    final scrollItems = provider.buildScrollItems();
    final initialLocation = ReaderLocation(
      chapterIndex: provider.currentChapterIndex,
      charOffset: provider.committedLocation.charOffset,
    );
    final initialIndex =
        scrollItems.isEmpty
            ? 0
            : provider
                .scrollItemIndexForLocation(initialLocation)
                .clamp(0, scrollItems.length - 1)
                .toInt();

    return Padding(
      padding: EdgeInsets.only(
        top: provider.scrollViewportTopInset,
        bottom: provider.scrollViewportBottomInset,
      ),
      child: ScrollablePositionedList.builder(
        itemCount: scrollItems.length,
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        initialScrollIndex: initialIndex,
        initialAlignment:
            provider.visibleChapterAlignment.clamp(0.0, 1.0).toDouble(),
        physics:
            provider.shouldBlockScrollInputForRestore
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
        itemBuilder: (_, index) {
          final item = scrollItems[index];
          itemKeys.putIfAbsent(item.key, GlobalKey.new);
          return KeyedSubtree(
            key: itemKeys[item.key],
            child: switch (item.kind) {
              ReaderScrollItemKind.line => ScrollLineItemWidget(
                item: item,
                onTapUp: onContentTapUp,
                contentStyle: contentStyle,
                titleStyle: titleStyle,
                paddingLeft: provider.textPadding,
                backgroundColor: provider.currentTheme.backgroundColor,
                ttsPosition: provider.currentTtsPosition,
              ),
              ReaderScrollItemKind.placeholder => _buildPlaceholder(
                provider,
                item,
                onContentTapUp,
              ),
              ReaderScrollItemKind.separator => _buildSeparator(provider, item),
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(
    ReaderProvider provider,
    ReaderScrollItem item,
    GestureTapUpCallback? onContentTapUp,
  ) {
    _recordPlaceholderEstimate(provider, item.chapterIndex);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: onContentTapUp,
      child: Container(
        color: provider.currentTheme.backgroundColor,
        height: item.extent,
        alignment: Alignment.center,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: provider.currentTheme.textColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator(ReaderProvider provider, ReaderScrollItem item) {
    return Container(
      color: provider.currentTheme.backgroundColor,
      height: item.extent,
      alignment: Alignment.center,
      child: Container(
        width: 40,
        height: 1,
        color: provider.currentTheme.textColor.withValues(alpha: 0.16),
      ),
    );
  }

  void _recordPlaceholderEstimate(ReaderProvider provider, int chapterIndex) {
    if (provider.estimatedChapterContentHeight(chapterIndex) > 0) return;
    final heights = <double>[];
    for (final offset in [-1, 1]) {
      final neighbor = chapterIndex + offset;
      if (neighbor < 0 || neighbor >= provider.chapters.length) continue;
      final neighborHeight = provider.estimatedChapterContentHeight(neighbor);
      if (neighborHeight > 0) heights.add(neighborHeight);
    }
    final viewportHeight =
        ((provider.viewSize?.height ?? 600.0) -
                provider.contentTopInset -
                provider.contentBottomInset)
            .clamp(1.0, double.infinity)
            .toDouble();
    provider.recordEstimatedPlaceholderChapterContentHeight(
      chapterIndex,
      contentHeight:
          heights.isEmpty
              ? viewportHeight
              : heights.reduce((double a, double b) => a + b) / heights.length,
    );
  }
}

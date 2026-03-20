import 'package:flutter/material.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/page_view_widget.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'page_mode_delegate.dart';

class ScrollModeDelegate extends PageModeDelegate {
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Map<String, GlobalKey> pageKeys;
  final bool Function() isUserScrolling;

  const ScrollModeDelegate({
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.pageKeys,
    required this.isUserScrolling,
  });

  @override
  Widget build({
    required BuildContext context,
    required ReaderProvider provider,
    required PageController pageController,
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

    return ScrollablePositionedList.builder(
      itemCount: provider.chapters.length,
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      initialScrollIndex: provider.chapters.isEmpty
          ? 0
          : provider.currentChapterIndex
              .clamp(0, provider.chapters.length - 1)
              .toInt(),
      initialAlignment:
          provider.visibleChapterAlignment.clamp(0.0, 1.0).toDouble(),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (_, chapterIndex) {
        final runtimeChapter = provider.chapterAt(chapterIndex);
        final pages = runtimeChapter?.pages;
        if (pages == null || pages.isEmpty) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            constraints: BoxConstraints(
              minHeight: (provider.viewSize?.height ?? 220) * 0.45,
            ),
            alignment: Alignment.center,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: provider.currentTheme.textColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  provider.loadingChapters.contains(chapterIndex)
                      ? '正在載入 ${provider.displayChapterTitleAt(chapterIndex)}...'
                      : '準備章節內容...',
                  style: TextStyle(
                    color: provider.currentTheme.textColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          );
        }
        return Container(
          color: provider.currentTheme.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final page in pages)
                SizedBox(
                  key: pageKeys.putIfAbsent(
                    '$chapterIndex:${page.index}',
                    GlobalKey.new,
                  ),
                  height: ChapterPositionResolver.pageHeight(page),
                  child: PageViewWidget(
                    page: page,
                    contentStyle: contentStyle,
                    titleStyle: titleStyle,
                    isScrollMode: true,
                    paddingTop: 0,
                    paddingBottom: 0,
                    ttsStart: provider.ttsStart,
                    ttsEnd: provider.ttsEnd,
                    ttsChapterIndex: provider.ttsChapterIndex,
                    pageBackgroundColor: provider.currentTheme.backgroundColor,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

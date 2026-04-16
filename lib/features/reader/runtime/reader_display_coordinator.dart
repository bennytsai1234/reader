import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_position_resolver.dart';

class ReaderDisplayInstruction {
  final ReaderLocation location;
  final ReaderScrollTarget? scrollTarget;
  final int? slidePageIndex;

  const ReaderDisplayInstruction({
    required this.location,
    this.scrollTarget,
    this.slidePageIndex,
  });
}

class ReaderDisplayCoordinator {
  const ReaderDisplayCoordinator();

  ReaderDisplayInstruction resolveDisplayInstruction({
    required int chapterIndex,
    required int persistedCharOffset,
    required bool fromEnd,
    required bool isScrollMode,
    required List<TextPage> chapterPages,
    required List<TextPage> slidePages,
    required ReaderChapter? runtimeChapter,
  }) {
    final location = ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: fromEnd && chapterPages.isNotEmpty
          ? ChapterPositionResolver.getCharOffsetForPage(
              chapterPages,
              chapterPages.length - 1,
            )
          : persistedCharOffset,
    ).normalized();

    if (isScrollMode) {
      return ReaderDisplayInstruction(
        location: location,
        scrollTarget: ReaderPositionResolver.resolveScrollTarget(
          location: location,
          runtimeChapter: runtimeChapter,
          pages: chapterPages,
        ),
      );
    }

    return ReaderDisplayInstruction(
      location: location,
      slidePageIndex: ReaderPositionResolver.resolveSlideTarget(
        location: location,
        runtimeChapter: runtimeChapter,
        chapterPages: chapterPages,
        slidePages: slidePages,
        targetChapterIndex: chapterIndex,
      ).globalPageIndex,
    );
  }

  int resolveSlideTargetIndex({
    required ReaderLocation? pinnedLocation,
    required bool pinnedFromEnd,
    required int? previousMappedIndex,
    required int currentChapterIndex,
    required int persistedCharOffset,
    required List<TextPage> slidePages,
    required ReaderChapter? Function(int chapterIndex) chapterAt,
    required List<TextPage> Function(int chapterIndex) pagesForChapter,
  }) {
    if (pinnedLocation != null) {
      if (pinnedFromEnd) {
        for (var i = slidePages.length - 1; i >= 0; i--) {
          if (slidePages[i].chapterIndex == pinnedLocation.chapterIndex) {
            return i;
          }
        }
      }
      return ReaderPositionResolver.resolveSlideTarget(
        location: pinnedLocation,
        runtimeChapter: chapterAt(pinnedLocation.chapterIndex),
        chapterPages: pagesForChapter(pinnedLocation.chapterIndex),
        slidePages: slidePages,
        targetChapterIndex: pinnedLocation.chapterIndex,
      ).globalPageIndex;
    }

    if (previousMappedIndex != null && previousMappedIndex >= 0) {
      return previousMappedIndex;
    }

    return ReaderPositionResolver.resolveSlideTarget(
      location: ReaderLocation(
        chapterIndex: currentChapterIndex,
        charOffset: persistedCharOffset,
      ),
      runtimeChapter: chapterAt(currentChapterIndex),
      chapterPages: pagesForChapter(currentChapterIndex),
      slidePages: slidePages,
      targetChapterIndex: currentChapterIndex,
    ).globalPageIndex;
  }
}

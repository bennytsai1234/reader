import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_display_coordinator.dart';

class ReaderContentPresentation {
  final ReaderLocation location;
  final ReaderScrollTarget? scrollTarget;
  final int? slidePageIndex;

  const ReaderContentPresentation({
    required this.location,
    this.scrollTarget,
    this.slidePageIndex,
  });
}

class ReaderContentCoordinator {
  final ReaderDisplayCoordinator _displayCoordinator;

  const ReaderContentCoordinator({
    ReaderDisplayCoordinator displayCoordinator =
        const ReaderDisplayCoordinator(),
  }) : _displayCoordinator = displayCoordinator;

  ReaderContentPresentation resolvePresentation({
    required int chapterIndex,
    required int persistedCharOffset,
    required bool fromEnd,
    required bool isScrollMode,
    required List<TextPage> chapterPages,
    required List<TextPage> slidePages,
    required ReaderChapter? runtimeChapter,
  }) {
    final instruction = _displayCoordinator.resolveDisplayInstruction(
      chapterIndex: chapterIndex,
      persistedCharOffset: persistedCharOffset,
      fromEnd: fromEnd,
      isScrollMode: isScrollMode,
      chapterPages: chapterPages,
      slidePages: slidePages,
      runtimeChapter: runtimeChapter,
    );
    return ReaderContentPresentation(
      location: instruction.location,
      scrollTarget: instruction.scrollTarget,
      slidePageIndex: instruction.slidePageIndex,
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
    return _displayCoordinator.resolveSlideTargetIndex(
      pinnedLocation: pinnedLocation,
      pinnedFromEnd: pinnedFromEnd,
      previousMappedIndex: previousMappedIndex,
      currentChapterIndex: currentChapterIndex,
      persistedCharOffset: persistedCharOffset,
      slidePages: slidePages,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
    );
  }
}

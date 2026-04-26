import 'package:flutter/widgets.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_scroll_item.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_layout.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

typedef ReaderVisibleScrollUpdate =
    ({
      int chapterIndex,
      double localOffset,
      double alignment,
      List<int> visibleChapterIndexes,
      ReaderLocation? anchorLocation,
      bool isAnchorConfirmed,
    });

class ReaderViewportLayoutUpdate {
  final bool shouldRepaginate;
  final Size? nextViewSize;

  const ReaderViewportLayoutUpdate({
    this.shouldRepaginate = false,
    this.nextViewSize,
  });
}

class ReaderViewportExecutionBridge {
  const ReaderViewportExecutionBridge();

  ReaderViewportLayoutUpdate resolveLayoutUpdate({
    required Size size,
    required bool contentInsetsChanged,
    required bool scrollInsetsChanged,
    required Size? currentViewSize,
    required bool isReady,
  }) {
    return ReaderViewportLayoutUpdate(
      shouldRepaginate:
          (contentInsetsChanged || scrollInsetsChanged) &&
          currentViewSize == size &&
          isReady,
      nextViewSize: currentViewSize != size ? size : null,
    );
  }

  ReaderVisibleScrollUpdate? resolveVisibleScrollUpdate({
    required Iterable<ItemPosition> positions,
    required double viewportHeight,
    required double Function(int chapterIndex) chapterHeightFor,
    required double Function(int chapterIndex) chapterItemExtentFor,
  }) {
    final sorted =
        positions.toList()
          ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    if (sorted.isEmpty) return null;

    final visible =
        sorted
            .where(
              (item) => item.itemTrailingEdge > 0 && item.itemLeadingEdge < 1,
            )
            .toList();
    if (visible.isEmpty) return null;

    final normalizedViewportHeight = viewportHeight <= 0 ? 1.0 : viewportHeight;
    final anchorY = normalizedViewportHeight * ReaderScrollLayout.anchorRatio;
    ItemPosition focusItem = visible.first;
    for (final item in visible) {
      final leading = item.itemLeadingEdge * normalizedViewportHeight;
      final trailing = item.itemTrailingEdge * normalizedViewportHeight;
      if (leading <= anchorY && trailing > anchorY) {
        focusItem = item;
        break;
      }
    }
    final focusItemLeading =
        focusItem.itemLeadingEdge * normalizedViewportHeight;
    final rawAnchorOffset =
        (anchorY - focusItemLeading).clamp(0.0, double.infinity).toDouble();
    final chapterItemExtent = chapterItemExtentFor(focusItem.index);
    final rawLocalOffset =
        chapterItemExtent > 0
            ? rawAnchorOffset.clamp(0.0, chapterItemExtent).toDouble()
            : rawAnchorOffset;
    final chapterHeight = chapterHeightFor(focusItem.index);
    final localOffset =
        chapterHeight > 0
            ? rawLocalOffset.clamp(0.0, chapterHeight).toDouble()
            : rawLocalOffset;

    return (
      chapterIndex: focusItem.index,
      localOffset: localOffset,
      alignment: 0.0,
      visibleChapterIndexes: visible.map((item) => item.index).toList(),
      anchorLocation: null,
      isAnchorConfirmed: false,
    );
  }

  ReaderVisibleScrollUpdate? resolveVisibleScrollItemUpdate({
    required Iterable<ItemPosition> positions,
    required double viewportHeight,
    required List<ReaderScrollItem> scrollItems,
    required double Function(int chapterIndex) chapterHeightFor,
  }) {
    if (scrollItems.isEmpty) return null;
    final normalizedViewportHeight = viewportHeight <= 0 ? 1.0 : viewportHeight;
    final visible =
        positions
            .where(
              (item) =>
                  item.index >= 0 &&
                  item.index < scrollItems.length &&
                  item.itemTrailingEdge > 0 &&
                  item.itemLeadingEdge < 1,
            )
            .toList()
          ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    if (visible.isEmpty) return null;

    final visibleChapterIndexes = <int>[];
    for (final position in visible) {
      final chapterIndex = scrollItems[position.index].chapterIndex;
      if (!visibleChapterIndexes.contains(chapterIndex)) {
        visibleChapterIndexes.add(chapterIndex);
      }
    }

    final anchorY = normalizedViewportHeight * ReaderScrollLayout.anchorRatio;
    for (final position in visible) {
      final item = scrollItems[position.index];
      final itemTop = position.itemLeadingEdge * normalizedViewportHeight;
      final itemBottom = position.itemTrailingEdge * normalizedViewportHeight;
      if (!item.isTextLine || itemBottom <= anchorY) continue;

      final yInsideItem = (anchorY - itemTop).clamp(0.0, item.extent);
      if (itemTop <= anchorY && yInsideItem >= item.linePaintHeight) {
        continue;
      }

      final chapterHeight = chapterHeightFor(item.chapterIndex);
      final alignment =
          chapterHeight <= 0
              ? 0.0
              : (item.localTop / chapterHeight).clamp(0.0, 1.0).toDouble();
      return (
        chapterIndex: item.chapterIndex,
        localOffset: item.localTop,
        alignment: alignment,
        visibleChapterIndexes: visibleChapterIndexes,
        anchorLocation: item.location,
        isAnchorConfirmed: true,
      );
    }

    final firstItem = scrollItems[visible.first.index];
    return (
      chapterIndex: firstItem.chapterIndex,
      localOffset: firstItem.localTop,
      alignment: 0.0,
      visibleChapterIndexes: visibleChapterIndexes,
      anchorLocation: null,
      isAnchorConfirmed: false,
    );
  }
}

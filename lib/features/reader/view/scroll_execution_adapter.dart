import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_scroll_item.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_scroll_layout.dart';

class ReaderScrollAnchorLocation {
  final int chapterIndex;
  final int pageIndex;
  final double localOffset;
  final ReaderLocation? location;

  const ReaderScrollAnchorLocation({
    required this.chapterIndex,
    required this.pageIndex,
    required this.localOffset,
    this.location,
  });
}

class ScrollExecutionAdapter {
  final Map<String, GlobalKey> itemKeys;
  final VoidCallback? onStateChanged;

  const ScrollExecutionAdapter({required this.itemKeys, this.onStateChanged});

  bool scrollByDelta({
    required ReaderProvider provider,
    required double deltaPixels,
  }) {
    if (deltaPixels <= 0) return false;
    final position = _resolveActiveScrollPosition(provider);
    if (position == null || !position.hasPixels) return false;
    final currentPixels = position.pixels;
    final targetPixels = (currentPixels + deltaPixels).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((targetPixels - currentPixels).abs() < 0.1) return false;
    position.jumpTo(targetPixels);
    onStateChanged?.call();
    return true;
  }

  void scrollToChapterLocalOffset({
    required ReaderProvider provider,
    required int chapterIndex,
    required double localOffset,
    bool animate = false,
    Duration duration = Duration.zero,
    double topPadding = 0.0,
  }) {
    final itemIndex = provider.scrollItemIndexForLocalOffset(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
    );
    final item = provider.scrollItemAt(itemIndex);
    if (item == null) return;
    final context = itemKeys[item.key]?.currentContext;
    if (context == null) return;
    final viewportObject =
        Scrollable.maybeOf(context)?.context.findRenderObject();
    final viewportHeight =
        viewportObject is RenderBox && viewportObject.size.height > 0
            ? viewportObject.size.height
            : 1.0;
    final alignment = (topPadding / viewportHeight).clamp(0.0, 1.0).toDouble();
    Scrollable.ensureVisible(
      context,
      duration: animate ? duration : Duration.zero,
      alignment: alignment,
      curve: Curves.easeOut,
    );
    onStateChanged?.call();
  }

  ReaderScrollAnchorLocation? resolveAnchorLocation({
    required ReaderProvider provider,
    double anchorRatio = ReaderScrollLayout.anchorRatio,
  }) {
    final scrollItems = provider.buildScrollItems();
    final visibleItems = <_VisibleScrollItemGeometry>[];
    for (var index = 0; index < scrollItems.length; index++) {
      final item = scrollItems[index];
      final itemContext = itemKeys[item.key]?.currentContext;
      final renderObject = itemContext?.findRenderObject();
      final viewportObject =
          itemContext == null
              ? null
              : Scrollable.maybeOf(itemContext)?.context.findRenderObject();
      if (renderObject is! RenderBox || viewportObject is! RenderBox) continue;

      final itemTop =
          renderObject.localToGlobal(Offset.zero, ancestor: viewportObject).dy;
      final itemHeight = renderObject.size.height;
      final itemBottom = itemTop + itemHeight;
      final viewportHeight = viewportObject.size.height;
      if (itemBottom <= 0 || itemTop >= viewportHeight || itemHeight <= 0) {
        continue;
      }
      visibleItems.add(
        _VisibleScrollItemGeometry(
          item: item,
          itemTop: itemTop,
          itemHeight: itemHeight,
          viewportHeight: viewportHeight,
        ),
      );
    }

    if (visibleItems.isEmpty) return null;
    visibleItems.sort((a, b) => a.itemTop.compareTo(b.itemTop));
    final viewportHeight = visibleItems.first.viewportHeight;
    final anchorY = viewportHeight * anchorRatio.clamp(0.0, 1.0);

    for (final geometry in visibleItems) {
      final item = geometry.item;
      if (!item.isTextLine || geometry.itemBottom <= anchorY) continue;
      final yInsideItem = (anchorY - geometry.itemTop).clamp(0.0, item.extent);
      if (geometry.itemTop <= anchorY && yInsideItem >= item.linePaintHeight) {
        continue;
      }
      return ReaderScrollAnchorLocation(
        chapterIndex: item.chapterIndex,
        pageIndex: item.lineItem?.pageIndex ?? -1,
        localOffset: item.localTop,
        location: item.location,
      );
    }

    final firstItem = visibleItems.first.item;
    return ReaderScrollAnchorLocation(
      chapterIndex: firstItem.chapterIndex,
      pageIndex: firstItem.lineItem?.pageIndex ?? -1,
      localOffset: firstItem.localTop,
    );
  }

  ScrollPosition? _resolveActiveScrollPosition(ReaderProvider provider) {
    final itemIndex = provider.scrollItemIndexForLocalOffset(
      chapterIndex: provider.visibleChapterIndex,
      localOffset: provider.visibleChapterLocalOffset,
    );
    final item = provider.scrollItemAt(itemIndex);
    final primaryContext =
        item == null ? null : itemKeys[item.key]?.currentContext;
    final primaryPosition = _scrollPositionFromContext(primaryContext);
    if (primaryPosition != null) return primaryPosition;
    for (final key in itemKeys.values) {
      final position = _scrollPositionFromContext(key.currentContext);
      if (position != null) return position;
    }
    return null;
  }

  ScrollPosition? _scrollPositionFromContext(BuildContext? context) {
    if (context == null) return null;
    return Scrollable.maybeOf(context)?.position;
  }
}

class _VisibleScrollItemGeometry {
  final ReaderScrollItem item;
  final double itemTop;
  final double itemHeight;
  final double viewportHeight;

  const _VisibleScrollItemGeometry({
    required this.item,
    required this.itemTop,
    required this.itemHeight,
    required this.viewportHeight,
  });

  double get itemBottom => itemTop + itemHeight;
}

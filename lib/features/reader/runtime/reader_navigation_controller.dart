import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:legado_reader/features/reader/runtime/reader_command_guard.dart';

class ReaderNavigationController {
  final ReaderCommandGuard _commandGuard = ReaderCommandGuard();
  DateTime? _suppressViewportProgressUntil;
  ReaderCommandReason _lastPendingSlideJumpReason = ReaderCommandReason.system;
  ReaderCommandReason _nextPageChangeReason = ReaderCommandReason.user;

  ReaderCommandReason? get activeCommandReason => _commandGuard.activeReason;

  bool beginSlideJump(ReaderCommandReason reason) {
    if (!_commandGuard.begin(reason)) return false;
    _lastPendingSlideJumpReason = reason;
    _suppressViewportProgressUntil = _suppressionDeadlineFor(reason);
    return true;
  }

  bool beginChapterJump(ReaderCommandReason reason) {
    if (!_commandGuard.begin(reason)) return false;
    _suppressViewportProgressUntil = _suppressionDeadlineFor(reason, isChapter: true);
    return true;
  }

  bool beginCharJump(ReaderCommandReason reason) {
    return _commandGuard.begin(reason);
  }

  bool canPersistProgress(ReaderCommandReason reason) {
    return _commandGuard.canDispatch(reason);
  }

  bool shouldPersistVisiblePosition([DateTime? now]) {
    final until = _suppressViewportProgressUntil;
    if (until == null) return true;
    return (now ?? DateTime.now()).isAfter(until);
  }

  ReaderCommandReason consumePendingSlideJumpReason() {
    final reason = _lastPendingSlideJumpReason;
    _lastPendingSlideJumpReason = ReaderCommandReason.system;
    _nextPageChangeReason = reason;
    return reason;
  }

  ReaderCommandReason consumePageChangeReason() {
    final reason = _nextPageChangeReason;
    _nextPageChangeReason = ReaderCommandReason.user;
    if (reason != ReaderCommandReason.restore) {
      _commandGuard.clear(reason);
    }
    return reason;
  }

  bool shouldPersistForReason(ReaderCommandReason reason) {
    switch (reason) {
      case ReaderCommandReason.user:
      case ReaderCommandReason.userScroll:
      case ReaderCommandReason.chapterChange:
        return true;
      case ReaderCommandReason.restore:
      case ReaderCommandReason.tts:
      case ReaderCommandReason.autoPage:
      case ReaderCommandReason.settingsRepaginate:
      case ReaderCommandReason.system:
        return false;
    }
  }

  void clear(ReaderCommandReason reason) {
    _commandGuard.clear(reason);
  }

  ({int chapterIndex, double localOffset})? nextAutoScrollTarget({
    required bool isAutoPaging,
    required Object pageTurnMode,
    required Size? viewSize,
    required int visibleChapterIndex,
    required double visibleChapterLocalOffset,
    required double Function(Size viewSize, double dtSeconds) scrollDeltaPerFrame,
    required ReaderChapter? Function(int) chapterAt,
    required List<TextPage> Function(int) pagesForChapter,
    required double dtSeconds,
  }) {
    if (!isAutoPaging || pageTurnMode != PageAnim.scroll) return null;
    final size = viewSize;
    if (size == null) return null;
    final chapterIndex = visibleChapterIndex;
    final runtimeChapter = chapterAt(chapterIndex);
    final chapterHeight = runtimeChapter?.chapterHeight ??
        ChapterPositionResolver.chapterHeight(pagesForChapter(chapterIndex));
    if (chapterHeight <= 0) return null;
    final delta = scrollDeltaPerFrame(size, dtSeconds);
    final nextLocalOffset = visibleChapterLocalOffset + delta;
    if (nextLocalOffset >= chapterHeight) return null;
    return (chapterIndex: chapterIndex, localOffset: nextLocalOffset);
  }

  ({
    int? chapterIndex,
    double? localOffset,
    bool advanceChapter,
  })? evaluateScrollAutoPageStep({
    required bool isAutoPaging,
    required bool isAutoPagePaused,
    required bool isLoading,
    required Object pageTurnMode,
    required Size? viewSize,
    required int visibleChapterIndex,
    required double visibleChapterLocalOffset,
    required double Function(Size viewSize, double dtSeconds) scrollDeltaPerFrame,
    required ReaderChapter? Function(int) chapterAt,
    required List<TextPage> Function(int) pagesForChapter,
    required double dtSeconds,
  }) {
    if (!isAutoPaging || isAutoPagePaused || pageTurnMode != PageAnim.scroll) {
      return null;
    }
    final target = nextAutoScrollTarget(
      isAutoPaging: isAutoPaging,
      pageTurnMode: pageTurnMode,
      viewSize: viewSize,
      visibleChapterIndex: visibleChapterIndex,
      visibleChapterLocalOffset: visibleChapterLocalOffset,
      scrollDeltaPerFrame: scrollDeltaPerFrame,
      chapterAt: chapterAt,
      pagesForChapter: pagesForChapter,
      dtSeconds: dtSeconds,
    );
    if (target != null) {
      return (
        chapterIndex: target.chapterIndex,
        localOffset: target.localOffset,
        advanceChapter: false,
      );
    }
    if (!isLoading) {
      return (chapterIndex: null, localOffset: null, advanceChapter: true);
    }
    return null;
  }

  DateTime? _suppressionDeadlineFor(
    ReaderCommandReason reason, {
    bool isChapter = false,
  }) {
    if (reason == ReaderCommandReason.user ||
        reason == ReaderCommandReason.userScroll) {
      return null;
    }
    return DateTime.now().add(
      Duration(milliseconds: isChapter ? 700 : 500),
    );
  }
}

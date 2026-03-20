import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'package:legado_reader/features/reader/view/delegate/scroll_mode_delegate.dart';
import 'package:legado_reader/features/reader/view/delegate/slide_mode_delegate.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ReadViewRuntime extends StatefulWidget {
  final ReaderProvider provider;
  final PageController pageController;

  const ReadViewRuntime({
    super.key,
    required this.provider,
    required this.pageController,
  });

  @override
  State<ReadViewRuntime> createState() => _ReadViewRuntimeState();
}

class _ReadViewRuntimeState extends State<ReadViewRuntime>
    with TickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final Map<String, GlobalKey> _pageKeys = {};
  Ticker? _autoScrollTicker;
  Duration _lastTickTime = Duration.zero;
  Timer? _userScrollResetTimer;
  bool _isUserScrolling = false;
  int _lastTtsScrolledStart = -1;
  int _lastPreloadChapterIndex = -1;
  int _pendingRestoreToken = 0;
  int? _pendingRestoreChapterIndex;
  double? _pendingRestoreLocalOffset;
  final Set<int> _requestedVisibleChapterLoads = <int>{};

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_onProviderStateChanged);
    _itemPositionsListener.itemPositions.addListener(_handleItemPositionsChanged);
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderStateChanged);
    _itemPositionsListener.itemPositions.removeListener(_handleItemPositionsChanged);
    _stopScrollAutoPage();
    _userScrollResetTimer?.cancel();
    widget.provider.setScrollInteractionActive(false);
    super.dispose();
  }

  void _onProviderStateChanged() {
    if (!mounted) return;
    final p = widget.provider;
    _requestedVisibleChapterLoads.removeWhere(p.hasRuntimeChapter);

    if (p.pageTurnMode == PageAnim.scroll && p.isAutoPaging && !p.isAutoPagePaused) {
      _startScrollAutoPage();
    } else {
      _stopScrollAutoPage();
    }

    final pendingChapterJump = p.consumePendingChapterJump();
    if (pendingChapterJump != null && p.pageTurnMode == PageAnim.scroll) {
      if (p.isRestoring) {
        _pendingRestoreToken++;
        final token = _pendingRestoreToken;
        _pendingRestoreChapterIndex = pendingChapterJump.chapterIndex;
        _pendingRestoreLocalOffset = pendingChapterJump.localOffset;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreScrollPosition(
            provider: p,
            chapterIndex: pendingChapterJump.chapterIndex,
            localOffset: pendingChapterJump.localOffset,
            token: token,
          );
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpScrollPosition(
            chapterIndex: pendingChapterJump.chapterIndex,
            localOffset: pendingChapterJump.localOffset,
          );
        });
      }
    } else if (p.pageTurnMode == PageAnim.scroll &&
        p.isRestoring &&
        _pendingRestoreChapterIndex != null &&
        _pendingRestoreLocalOffset != null) {
      final token = _pendingRestoreToken;
      final chapterIndex = _pendingRestoreChapterIndex!;
      final localOffset = _pendingRestoreLocalOffset!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollPosition(
          provider: p,
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          token: token,
        );
      });
    }

    if (p.pageTurnMode == PageAnim.scroll &&
        p.ttsStart >= 0 &&
        p.ttsStart != _lastTtsScrolledStart &&
        !_isUserScrolling) {
      _lastTtsScrolledStart = p.ttsStart;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTtsHighlight();
      });
    }

    setState(() {});
  }

  void _handleItemPositionsChanged() {
    final p = widget.provider;
    if (p.pageTurnMode != PageAnim.scroll) return;
    final positions = _itemPositionsListener.itemPositions.value.toList()
      ..sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    if (positions.isEmpty) return;
    final visible = positions
        .where((item) => item.itemTrailingEdge > 0 && item.itemLeadingEdge < 1)
        .toList();
    if (visible.isEmpty) return;
    final topItem = visible.first;
    final chapterIndex = topItem.index;
    final viewportHeight = context.size?.height ?? 1.0;
    final localOffset = (-topItem.itemLeadingEdge * viewportHeight).clamp(0.0, double.infinity);
    p.updateVisibleChapterPosition(
      chapterIndex: chapterIndex,
      localOffset: localOffset,
      alignment: topItem.itemLeadingEdge.clamp(0.0, 1.0),
    );
    p.updateScrollPageIndex(chapterIndex, localOffset);
    for (final item in visible) {
      final visibleChapter = item.index;
      if (p.hasRuntimeChapter(visibleChapter) ||
          p.loadingChapters.contains(visibleChapter) ||
          _requestedVisibleChapterLoads.contains(visibleChapter)) {
        continue;
      }
      if ((visibleChapter - p.currentChapterIndex).abs() > 1) continue;
      _requestedVisibleChapterLoads.add(visibleChapter);
      unawaited(
        p.ensureChapterCached(
          visibleChapter,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        ),
      );
    }
    if (_lastPreloadChapterIndex != chapterIndex) {
      _lastPreloadChapterIndex = chapterIndex;
      p.updateScrollPreloadForVisibleChapter(chapterIndex);
    }
  }

  void _startScrollAutoPage() {
    if (_autoScrollTicker != null) return;
    _lastTickTime = Duration.zero;
    _autoScrollTicker = createTicker((elapsed) {
      if (!mounted) {
        _stopScrollAutoPage();
        return;
      }
      final p = widget.provider;
      if (!p.isAutoPaging || p.isAutoPagePaused || p.pageTurnMode != PageAnim.scroll) {
        _stopScrollAutoPage();
        return;
      }
      final viewSize = p.viewSize;
      if (viewSize == null) return;
      if (_lastTickTime == Duration.zero) {
        _lastTickTime = elapsed;
        return;
      }
      final dtSeconds =
          (elapsed.inMicroseconds - _lastTickTime.inMicroseconds) / 1000000.0;
      _lastTickTime = elapsed;
      final delta = p.scrollDeltaPerFrame(viewSize, dtSeconds);
      final pages = p.pagesForChapter(p.visibleChapterIndex);
      final nextLocalOffset = p.visibleChapterLocalOffset + delta;
      final chapterHeight = ChapterPositionResolver.chapterHeight(pages);
      if (chapterHeight > 0 && nextLocalOffset < chapterHeight) {
        _scrollToChapterLocalOffset(
          chapterIndex: p.visibleChapterIndex,
          localOffset: nextLocalOffset,
          animate: false,
        );
      } else if (!p.isLoading) {
        p.nextChapter();
      }
    });
    _autoScrollTicker!.start();
  }

  void _stopScrollAutoPage() {
    _autoScrollTicker?.stop();
    _autoScrollTicker?.dispose();
    _autoScrollTicker = null;
  }

  void _scrollToPageKey({
    required int chapterIndex,
    required int pageIndex,
    bool animate = false,
  }) {
    final key = _pageKeys['$chapterIndex:$pageIndex'];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: animate ? const Duration(milliseconds: 240) : Duration.zero,
      alignment: 0,
      curve: Curves.easeOut,
    );
  }

  void _scrollToChapterLocalOffset({
    required int chapterIndex,
    required double localOffset,
    bool animate = false,
    Duration duration = Duration.zero,
    double topPadding = 0.0,
  }) {
    final provider = widget.provider;
    final pages = provider.pagesForChapter(chapterIndex);
    if (pages.isEmpty) return;
    final pageIndex = ChapterPositionResolver.pageIndexAtLocalOffset(
      pages,
      localOffset,
    );
    final pageStartOffset = ChapterPositionResolver.getCharOffsetForPage(
      pages,
      pageIndex,
    );
    final pageStartLocalOffset = ChapterPositionResolver.charOffsetToLocalOffset(
      pages,
      pageStartOffset,
    );
    final intraPageOffset = (localOffset - pageStartLocalOffset).clamp(
      0.0,
      double.infinity,
    );
    final key = _pageKeys['$chapterIndex:$pageIndex'];
    final pageContext = key?.currentContext;
    if (pageContext == null) {
      _scrollToPageKey(
        chapterIndex: chapterIndex,
        pageIndex: pageIndex,
        animate: animate,
      );
      return;
    }
    Scrollable.ensureVisible(
      pageContext,
      duration: animate ? duration : Duration.zero,
      alignment: 0,
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final position = Scrollable.maybeOf(pageContext)?.position;
      final renderObject = pageContext.findRenderObject();
      final viewportObject = Scrollable.maybeOf(pageContext)?.context.findRenderObject();
      if (position == null ||
          renderObject is! RenderBox ||
          viewportObject is! RenderBox) {
        return;
      }
      final pageTop =
          renderObject.localToGlobal(Offset.zero, ancestor: viewportObject).dy;
      final targetPixels =
          (position.pixels + pageTop + intraPageOffset - topPadding).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (animate) {
        position.animateTo(
          targetPixels,
          duration: duration,
          curve: Curves.easeOut,
        );
      } else {
        position.jumpTo(targetPixels);
      }
    });
  }

  void _jumpScrollPosition({
    required int chapterIndex,
    required double localOffset,
  }) {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.jumpTo(
      index: chapterIndex,
      alignment: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        animate: false,
      );
    });
  }

  void _restoreScrollPosition({
    required ReaderProvider provider,
    required int chapterIndex,
    required double localOffset,
    required int token,
    int retries = 20,
  }) {
    if (!mounted || token != _pendingRestoreToken) return;
    if (!_itemScrollController.isAttached) {
      if (retries <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollPosition(
          provider: provider,
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          token: token,
          retries: retries - 1,
        );
      });
      return;
    }

    final pages = provider.pagesForChapter(chapterIndex);
    if (pages.isEmpty) {
      if (provider.loadingChapters.contains(chapterIndex) && retries > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreScrollPosition(
            provider: provider,
            chapterIndex: chapterIndex,
            localOffset: localOffset,
            token: token,
            retries: retries - 1,
          );
        });
        return;
      }
      unawaited(
        provider.ensureChapterCached(
          chapterIndex,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        ),
      );
      if (retries > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreScrollPosition(
            provider: provider,
            chapterIndex: chapterIndex,
            localOffset: localOffset,
            token: token,
            retries: retries - 1,
          );
        });
      }
      return;
    }

    _itemScrollController.jumpTo(
      index: chapterIndex,
      alignment: 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _pendingRestoreToken) return;
      final pageIndex = ChapterPositionResolver.pageIndexAtLocalOffset(
        pages,
        localOffset,
      );
      final key = _pageKeys['$chapterIndex:$pageIndex'];
      final pageContext = key?.currentContext;
      if (pageContext == null && retries > 0) {
        _restoreScrollPosition(
          provider: provider,
          chapterIndex: chapterIndex,
          localOffset: localOffset,
          token: token,
          retries: retries - 1,
        );
        return;
      }
      if (pageContext == null) return;
      _scrollToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: localOffset,
        animate: false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeScrollRestore(provider, token);
      });
    });
  }

  void _completeScrollRestore(ReaderProvider provider, int token) {
    if (!mounted || token != _pendingRestoreToken) return;
    _pendingRestoreChapterIndex = null;
    _pendingRestoreLocalOffset = null;
    provider.lifecycle = ReaderLifecycle.ready;
    setState(() {});
  }

  void _scrollToTtsHighlight() {
    final provider = widget.provider;
    final chapterIndex = provider.ttsChapterIndex >= 0
        ? provider.ttsChapterIndex
        : provider.currentChapterIndex;
    final pages = provider.pagesForChapter(chapterIndex);
    if (pages.isEmpty || provider.ttsStart < 0) return;
    final targetLocalOffset = ChapterPositionResolver.charOffsetToLocalOffset(
      pages,
      provider.ttsStart,
    );
    final viewportHeight = context.size?.height ?? 0.0;
    final anchorPadding = viewportHeight * 0.12;
    if (chapterIndex == provider.visibleChapterIndex && viewportHeight > 0) {
      final visibleTop = provider.visibleChapterLocalOffset;
      final visibleBottom = visibleTop + viewportHeight;
      if (targetLocalOffset <= anchorPadding && visibleTop <= 2.0) {
        return;
      }
      final safeTop = visibleTop + anchorPadding;
      final safeBottom = visibleBottom - (viewportHeight * 0.22);
      if (targetLocalOffset >= safeTop && targetLocalOffset <= safeBottom) {
        return;
      }
    }
    _itemScrollController.scrollTo(
      index: chapterIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToChapterLocalOffset(
        chapterIndex: chapterIndex,
        localOffset: targetLocalOffset,
        animate: true,
        duration: const Duration(milliseconds: 160),
        topPadding: targetLocalOffset < anchorPadding ? 0.0 : anchorPadding,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (provider.viewSize != size) {
          WidgetsBinding.instance.addPostFrameCallback((_) => provider.setViewSize(size));
        }

        final hasVisibleData = provider.pageTurnMode == PageAnim.scroll
            ? provider.pageFactory.orderedChapters.isNotEmpty
            : provider.slidePages.isNotEmpty;

        final waitingForFirstContent =
            !hasVisibleData &&
            (provider.lifecycle == ReaderLifecycle.loading ||
                provider.lifecycle == ReaderLifecycle.restoring ||
                provider.viewSize == null ||
                provider.chapters.isNotEmpty);
        final holdScrollUntilRestored =
            provider.pageTurnMode == PageAnim.scroll &&
            provider.lifecycle == ReaderLifecycle.restoring &&
            hasVisibleData;

        if ((provider.isLoading && !hasVisibleData) || waitingForFirstContent) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!hasVisibleData && !provider.isLoading) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: Center(
              child: Text(
                '暫無內容',
                style: TextStyle(color: provider.currentTheme.textColor.withAlpha(128)),
              ),
            ),
          );
        }

        if (provider.isRestoring && provider.pageTurnMode != PageAnim.scroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.pageController.hasClients &&
                widget.pageController.page?.round() != provider.currentPageIndex) {
              widget.pageController.jumpToPage(provider.currentPageIndex);
            }
            provider.lifecycle = ReaderLifecycle.ready;
          });
        }

        final delegate = provider.pageTurnMode == PageAnim.scroll
            ? ScrollModeDelegate(
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                pageKeys: _pageKeys,
                isUserScrolling: () => _isUserScrolling,
              )
            : const SlideModeDelegate();

        final content = NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (provider.pageTurnMode != PageAnim.scroll) return false;
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _isUserScrolling = true;
              _userScrollResetTimer?.cancel();
              provider.setScrollInteractionActive(true);
            } else if (notification is ScrollEndNotification) {
              _userScrollResetTimer?.cancel();
              _userScrollResetTimer = Timer(const Duration(milliseconds: 800), () {
                if (mounted) {
                  _isUserScrolling = false;
                  provider.setScrollInteractionActive(false);
                }
              });
            }
            return false;
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: delegate.build(
              context: context,
              provider: provider,
              pageController: widget.pageController,
            ),
          ),
        );

        if (holdScrollUntilRestored) {
          return Stack(
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: 0,
                  child: content,
                ),
              ),
              Container(
                color: provider.currentTheme.backgroundColor,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        return content;
      },
    );
  }
}

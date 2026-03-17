import 'dart:async';
import 'package:flutter/material.dart';
import '../reader_provider.dart';
import '../engine/page_view_widget.dart';

class ReaderViewBuilder extends StatefulWidget {
  final ReaderProvider provider;
  final PageController pageController;

  const ReaderViewBuilder({
    super.key,
    required this.provider,
    required this.pageController,
  });

  @override
  State<ReaderViewBuilder> createState() => _ReaderViewBuilderState();
}

class _ReaderViewBuilderState extends State<ReaderViewBuilder> {
  late ScrollController _scrollController;
  bool _isUserScrolling = false;

  // 捲動模式自動翻頁：60fps 高頻 Timer（對標 Android AutoPager）
  Timer? _autoScrollTimer;

  // TTS 捲動追蹤：記錄上一次已捲動的段落起始位置，避免重複捲動
  int _lastTtsScrolledStart = -1;

  // 追蹤上一次已知的頁面數量，只在真正變化時觸發 setState（減少不必要重建）
  int _lastKnownPagesLength = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);

    // 監聽 provider 狀態變化以啟停自動捲動
    widget.provider.addListener(_onProviderStateChanged);

    // 監聽 trim 補償：從頂部移除章節後向上移動等量像素，防止視覺位置跳動
    widget.provider.scrollTrimAdjustController.stream.listen((upBy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          final target = (_scrollController.offset - upBy)
              .clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.jumpTo(target);
        }
      });
    });

    // 監聽並跳轉捲動位置 (處理切換章節後的初始位置 / 開書恢復位置)
    widget.provider.scrollOffsetController.stream.listen((offset) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          if (offset >= 999999) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          } else if (offset < 0) {
            final double targetScroll = _scrollController.offset + offset.abs();
            _scrollController.jumpTo(targetScroll);
          } else if (offset > 0) {
            // 精確像素跳轉（由 _calcScrollOffsetForCharOffset 計算的開書恢復位置）
            _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
          } else {
            _scrollController.jumpTo(0);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderStateChanged);
    _stopScrollAutoPage();
    _scrollController.dispose();
    super.dispose();
  }

  /// Provider 狀態變化回調：根據自動翻頁狀態啟停捲動 Timer
  void _onProviderStateChanged() {
    if (!mounted) return;
    final p = widget.provider;

    // 頁面列表變化（章節載入或 trim）→ 觸發 ListView itemCount 更新
    if (p.pages.length != _lastKnownPagesLength) {
      _lastKnownPagesLength = p.pages.length;
      setState(() {});
    }

    if (p.pageTurnMode == 2 && p.isAutoPaging && !p.isAutoPagePaused) {
      _startScrollAutoPage();
    } else {
      _stopScrollAutoPage();
    }
    // 捲動模式：provider 更新後（章節載入完成）自動檢查是否需要載入鄰章
    if (p.pageTurnMode == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleScroll();
      });
    }
    // 捲動模式 TTS：段落切換時自動捲動使高亮行保持可見
    if (p.pageTurnMode == 2 && p.ttsStart >= 0 && p.ttsStart != _lastTtsScrolledStart) {
      _lastTtsScrolledStart = p.ttsStart;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToTtsHighlight();
      });
    }
  }

  /// 啟動捲動模式自動翻頁 Timer（60fps 像素級捲動）
  void _startScrollAutoPage() {
    if (_autoScrollTimer != null) return; // 已在運行，不重複啟動
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) {
        _stopScrollAutoPage();
        return;
      }
      final p = widget.provider;
      if (!p.isAutoPaging || p.isAutoPagePaused || p.pageTurnMode != 2) {
        _stopScrollAutoPage();
        return;
      }
      if (!_scrollController.hasClients) return;

      final viewSize = p.viewSize;
      if (viewSize == null) return;

      // 每 tick 捲動像素 = (頁高 / 速度秒數) * 0.016秒（對標 Android AutoPager）
      final tickDelta = (viewSize.height / p.autoPageSpeed.clamp(1.0, 600.0)) * 0.016;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      if (currentScroll < maxScroll - tickDelta) {
        _scrollController.jumpTo(currentScroll + tickDelta);
      } else if (currentScroll < maxScroll) {
        _scrollController.jumpTo(maxScroll);
      } else if (!p.isLoading) {
        // 到達章節末尾，自動加載下一章
        p.nextChapter();
      }
    });
  }

  /// 停止捲動模式自動翻頁 Timer
  void _stopScrollAutoPage() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _handleScroll() {
    if (widget.provider.pageTurnMode == 2) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.position.pixels;

        // 無論是否在使用者捲動中，都更新精確 scroll offset 供 dispose 儲存
        widget.provider.updateScrollOffset(currentScroll);

        if (_isUserScrolling) return;

        final firstPage = widget.provider.pages.firstOrNull;
        final lastPage = widget.provider.pages.lastOrNull;

        // 更新捲動模式的當前可見頁（供 TTS 起始位置使用）
        _updateScrollPageIndex(currentScroll);

        if (currentScroll <= 50 && !widget.provider.isLoading && firstPage != null && firstPage.chapterIndex > 0) {
           _isUserScrolling = true;
           widget.provider.prevChapter().then((_) {
             // 章節載入完成後清除鎖定；ListView 重建由 _onProviderStateChanged 負責
             if (mounted) _isUserScrolling = false;
           });
           return;
        }

        if (currentScroll >= maxScroll - 100 && !widget.provider.isLoading && lastPage != null && lastPage.chapterIndex < widget.provider.chapters.length - 1) {
          _isUserScrolling = true;
          widget.provider.nextChapter().then((_) {
            if (mounted) _isUserScrolling = false;
          });
        }
      }
    }
  }

  /// 根據捲動位置更新 currentPageIndex（捲動模式專用，供 TTS 定位）
  /// 需補償 showHead 的額外高度（2px head + 24px separator = 26px）及頁面間 24px 分隔
  void _updateScrollPageIndex(double currentScroll) {
    final provider = widget.provider;
    if (provider.pages.isEmpty) return;
    final firstPage = provider.pages.firstOrNull;
    final double headOffset = (firstPage != null && firstPage.chapterIndex > 0) ? 26.0 : 0.0;
    double cumHeight = headOffset;
    for (int i = 0; i < provider.pages.length; i++) {
      final page = provider.pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0;
      cumHeight += pageHeight;
      if (currentScroll < cumHeight) {
        provider.updateScrollPageIndex(i);
        return;
      }
      if (i < provider.pages.length - 1) cumHeight += 24.0;
    }
  }

  /// TTS 捲動追蹤：將當前朗讀段落捲動至可見範圍（段落切換時觸發一次）
  void _scrollToTtsHighlight() {
    if (!_scrollController.hasClients) return;
    final provider = widget.provider;
    if (provider.ttsStart < 0 || provider.pages.isEmpty) return;

    double cumHeight = 0;
    for (int i = 0; i < provider.pages.length; i++) {
      final page = provider.pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0;

      for (final line in page.lines) {
        if (line.image != null) continue;
        final lEnd = line.chapterPosition + line.text.length;
        if (provider.ttsStart >= line.chapterPosition && provider.ttsStart < lEnd) {
          final lineTop = cumHeight + 40.0 + line.lineTop;
          final lineBottom = cumHeight + 40.0 + line.lineBottom;
          final viewportH = _scrollController.position.viewportDimension;
          final currentOffset = _scrollController.offset;
          final maxOffset = _scrollController.position.maxScrollExtent;

          // 觸發條件：高亮行已離開視口（上方或下方），或位於視口下方 65% 區域
          // 目標位置：高亮行置於距頂端 25% 處，保留足夠的後續閱讀空間
          final comfortZoneBottom = currentOffset + viewportH * 0.65;
          if (lineTop < currentOffset || lineBottom > comfortZoneBottom) {
            final target = (lineTop - viewportH * 0.25).clamp(0.0, maxOffset);
            _scrollController.animateTo(
              target,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
          return;
        }
      }

      cumHeight += pageHeight;
      if (i < provider.pages.length - 1) cumHeight += 24.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (provider.viewSize != size) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.setViewSize(size);
          });
        }

        if (provider.isLoading && provider.pages.isEmpty) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.pages.isEmpty && !provider.isLoading) {
          return Container(
            color: provider.currentTheme.backgroundColor,
            child: Center(child: Text('暫無內容', style: TextStyle(color: provider.currentTheme.textColor.withValues(alpha: 0.5)))),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildModeReader(provider),
        );
      },
    );
  }

  Widget _buildModeReader(ReaderProvider provider) {
    switch (provider.pageTurnMode) {
      case 2:
        return _buildScrollReader();
      case 3:
        return _buildHorizontalReader(physics: const NeverScrollableScrollPhysics());
      case 0:
      case 1:
      default:
        return _buildHorizontalReader();
    }
  }

  Widget _buildHorizontalReader({ScrollPhysics? physics}) {
    final provider = widget.provider;
    final hasPrev = provider.currentChapterIndex > 0;
    final hasNext = provider.currentChapterIndex < provider.chapters.length - 1;
    final itemCount = (hasPrev ? 1 : 0) + provider.pages.length + (hasNext ? 1 : 0);

    return Listener(
      onPointerDown: (_) => provider.pauseAutoPage(),
      onPointerUp: (_) {
        // 延遲恢復，避免手動翻頁後立即被自動翻頁接管
        // 菜單顯示時不恢復（由 toggleControls 負責恢復）
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !provider.showControls) {
            provider.resumeAutoPage();
          }
        });
      },
      child: PageView.builder(
        controller: widget.pageController,
        physics: physics ?? const BouncingScrollPhysics(),
        itemCount: itemCount,
        onPageChanged: (i) {
          if (provider.pages.isEmpty || provider.isLoading) return;

          if (hasPrev && i == 0) {
            provider.prevChapter();
          } else if (hasNext && i == itemCount - 1) {
            provider.nextChapter();
          } else {
            final actualIndex = hasPrev ? i - 1 : i;
            provider.onPageChanged(actualIndex);
          }
        },
        itemBuilder: (ctx, i) {
          if (hasPrev && i == 0) {
            final isCached = provider.chapterCache.containsKey(provider.currentChapterIndex - 1);
            return _buildLoadingView('載入上一章...', showIndicator: !isCached);
          }
          if (hasNext && i == itemCount - 1) {
            final isCached = provider.chapterCache.containsKey(provider.currentChapterIndex + 1);
            return _buildLoadingView('載入下一章...', showIndicator: !isCached);
          }

          final idx = hasPrev ? i - 1 : i;
          if (idx < 0 || idx >= provider.pages.length) return const SizedBox.shrink();

          // 取得下一頁供分頁模式掃描線效果使用
          final nextIdx = idx + 1;
          final nextPage = (nextIdx < provider.pages.length) ? provider.pages[nextIdx] : null;
          return PageViewWidget(
            page: provider.pages[idx],
            nextPage: nextPage,
            contentStyle: _getContentStyle(),
            titleStyle: _getTitleStyle(),
            ttsStart: provider.ttsStart,
            ttsEnd: provider.ttsEnd,
            ttsChapterIndex: provider.ttsChapterIndex,
            isAutoPaging: provider.isAutoPaging,
            autoPageProgress: provider.autoPageProgress,
            pageBackgroundColor: provider.currentTheme.backgroundColor,
            onLineTap: provider.tts.isPlaying
                ? (lineIdx) => provider.startTtsFromLine(lineIdx)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildScrollReader() {
    final firstPage = widget.provider.pages.firstOrNull;
    final lastPage = widget.provider.pages.lastOrNull;
    final showHead = firstPage != null && firstPage.chapterIndex > 0;
    final showTail = lastPage != null && lastPage.chapterIndex < widget.provider.chapters.length - 1;

    return Listener(
      onPointerDown: (_) {
        setState(() => _isUserScrolling = true);
        widget.provider.pauseAutoPage();
      },
      onPointerUp: (_) {
        // 延遲恢復，避免手動捲動慣性被自動翻頁立即接管導致抖動
        // 菜單顯示時不恢復
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _isUserScrolling = false);
            if (!widget.provider.showControls) {
              widget.provider.resumeAutoPage();
            }
          }
        });
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _handleScroll();
          }
          return false;
        },
        child: ListView.separated(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          itemCount: widget.provider.pages.length + (showHead ? 1 : 0) + (showTail ? 1 : 0),
          separatorBuilder: (ctx, i) => const SizedBox(height: 24),
          itemBuilder: (ctx, i) {
            if (showHead && i == 0) {
              return _buildScrollLoadingHead();
            }

            final actualIndex = showHead ? i - 1 : i;

            if (showTail && actualIndex == widget.provider.pages.length) {
              return _buildScrollLoadingTail();
            }

            if (actualIndex < 0 || actualIndex >= widget.provider.pages.length) {
              return const SizedBox.shrink();
            }

            final page = widget.provider.pages[actualIndex];
            final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom + 40.0;

            return SizedBox(
              height: pageHeight,
              child: PageViewWidget(
                page: page,
                contentStyle: _getContentStyle(),
                titleStyle: _getTitleStyle(),
                isScrollMode: true,
                ttsStart: widget.provider.ttsStart,
                ttsEnd: widget.provider.ttsEnd,
                ttsChapterIndex: widget.provider.ttsChapterIndex,
              ),
            );
          },
        ),
      ),
    );
  }

  TextStyle _getContentStyle() {
    final p = widget.provider;
    return TextStyle(fontSize: p.fontSize, height: p.lineHeight, color: p.currentTheme.textColor, letterSpacing: p.letterSpacing);
  }

  TextStyle _getTitleStyle() {
    final p = widget.provider;
    return TextStyle(fontSize: p.fontSize + 4, fontWeight: FontWeight.bold, color: p.currentTheme.textColor, letterSpacing: p.letterSpacing);
  }

  Widget _buildLoadingView(String text, {bool showIndicator = true}) {
    return Container(
      color: widget.provider.currentTheme.backgroundColor,
      child: showIndicator
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(height: 20),
                  Text(text, style: TextStyle(color: widget.provider.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 13)),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildScrollLoadingTail() {
    final provider = widget.provider;
    final lastChapterIndex = provider.pages.lastOrNull?.chapterIndex ?? provider.currentChapterIndex;
    final nextIndex = lastChapterIndex + 1;
    final hasNext = nextIndex < provider.chapters.length;
    final isLoading = hasNext && provider.loadingChapters.contains(nextIndex);

    if (!hasNext) {
      return Container(
        color: provider.currentTheme.backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            '全書完',
            style: TextStyle(color: provider.currentTheme.textColor.withValues(alpha: 0.3), fontSize: 14),
          ),
        ),
      );
    }

    if (isLoading) {
      return Container(
        color: provider.currentTheme.backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Text('正在載入下一章...', style: TextStyle(color: provider.currentTheme.textColor.withValues(alpha: 0.3), fontSize: 14)),
              const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
        ),
      );
    }

    // 有下一章但尚未觸發載入：顯示細分隔線，不展示加載動畫
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        value: 1.0,
        backgroundColor: provider.currentTheme.backgroundColor,
        color: provider.currentTheme.textColor.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildScrollLoadingHead() {
    final provider = widget.provider;
    final firstChapterIndex = provider.pages.firstOrNull?.chapterIndex ?? provider.currentChapterIndex;
    final prevIndex = firstChapterIndex - 1;
    final isLoading = prevIndex >= 0 && provider.loadingChapters.contains(prevIndex);

    if (isLoading) {
      return Container(
        color: provider.currentTheme.backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 16),
              Text('正在載入上一章...', style: TextStyle(color: provider.currentTheme.textColor.withValues(alpha: 0.3), fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // 有上一章但尚未觸發載入：顯示細分隔線
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        value: 1.0,
        backgroundColor: provider.currentTheme.backgroundColor,
        color: provider.currentTheme.textColor.withValues(alpha: 0.1),
      ),
    );
  }
}

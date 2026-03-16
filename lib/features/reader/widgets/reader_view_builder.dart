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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (widget.provider.pageTurnMode == 2 && widget.provider.isAutoPaging && !_isUserScrolling) {
      // 可以在這裡偵測是否滾動到章節末尾並切換章節
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    
    if (provider.isLoading && provider.pages.isEmpty) {
      return Container(
        color: provider.currentTheme.backgroundColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 當自動翻頁開啟且為捲動模式時，啟動平滑捲動
    if (provider.isAutoPaging && provider.pageTurnMode == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startSmoothScroll());
    }

    switch (provider.pageTurnMode) {
      case 2: // 捲動模式 (Vertical Scroll)
        return _buildScrollReader();
      case 3: // 無動畫
        return _buildHorizontalReader(physics: const NeverScrollableScrollPhysics());
      case 0: // 平移 (Normal)
      case 1: // 仿真 (模擬)
      default:
        return _buildHorizontalReader();
    }
  }

  void _startSmoothScroll() {
    if (!_scrollController.hasClients || _isUserScrolling) return;
    
    // 計算滾動增量 (對標 Android 速度級別)
    final double speedFactor = widget.provider.autoPageSpeed * 2.0;
    final double currentOffset = _scrollController.offset;
    final double maxOffset = _scrollController.position.maxScrollExtent;

    if (currentOffset < maxOffset) {
      _scrollController.animateTo(
        currentOffset + 50,
        duration: Duration(milliseconds: (5000 / speedFactor).round()),
        curve: Curves.linear,
      );
    } else {
      // 滾動到底部，自動切換下一章
      widget.provider.nextChapter();
    }
  }

  Widget _buildHorizontalReader({ScrollPhysics? physics}) {
    final provider = widget.provider;
    final hasPrev = provider.currentChapterIndex > 0;
    final hasNext = provider.currentChapterIndex < provider.chapters.length - 1;

    return PageView.builder(
      controller: widget.pageController,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: (hasPrev ? 1 : 0) + provider.pages.length + (hasNext ? 1 : 0),
      onPageChanged: (i) {
        final actualIndex = hasPrev ? i - 1 : i;
        if (hasPrev && i == 0) {
          provider.prevChapter();
        } else if (actualIndex == provider.pages.length) {
          provider.nextChapter();
        } else {
          provider.onPageChanged(actualIndex);
        }
      },
      itemBuilder: (ctx, i) {
        if (hasPrev && i == 0) return _buildLoadingView('載入上一章...');
        final idx = hasPrev ? i - 1 : i;
        if (idx == provider.pages.length) return _buildLoadingView('載入下一章...');
        
        return PageViewWidget(
          page: provider.pages[idx],
          contentStyle: _getContentStyle(),
          titleStyle: _getTitleStyle(),
        );
      },
    );
  }

  Widget _buildScrollReader() {
    return Listener(
      onPointerDown: (_) => setState(() => _isUserScrolling = true),
      onPointerUp: (_) => Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isUserScrolling = false);
      }),
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        itemCount: widget.provider.pages.length + 1,
        separatorBuilder: (ctx, i) => const SizedBox(height: 24),
        itemBuilder: (ctx, i) {
          if (i == widget.provider.pages.length) {
            return _buildScrollLoadingTail();
          }
          return PageViewWidget(
            page: widget.provider.pages[i],
            contentStyle: _getContentStyle(),
            titleStyle: _getTitleStyle(),
            isScrollMode: true,
          );
        },
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

  Widget _buildLoadingView(String text) {
    return Container(
      color: widget.provider.currentTheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 20),
            Text(text, style: TextStyle(color: widget.provider.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollLoadingTail() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Text('本章完', style: TextStyle(color: widget.provider.currentTheme.textColor.withValues(alpha: 0.3)))),
    );
  }
}

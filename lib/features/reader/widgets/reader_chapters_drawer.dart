import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';

class ReaderChaptersDrawer extends StatefulWidget {
  final ReaderProvider provider;

  const ReaderChaptersDrawer({super.key, required this.provider});

  @override
  State<ReaderChaptersDrawer> createState() => _ReaderChaptersDrawerState();
}

class _ReaderChaptersDrawerState extends State<ReaderChaptersDrawer> {
  static const double _tileExtent = 56.0;

  final ScrollController _scrollController = ScrollController();
  int _lastScrolledChapterIndex = -1;

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_handleProviderChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleScrollToCurrentChapter();
  }

  @override
  void didUpdateWidget(covariant ReaderChaptersDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      oldWidget.provider.removeListener(_handleProviderChanged);
      widget.provider.addListener(_handleProviderChanged);
      _lastScrolledChapterIndex = -1;
    }
    _scheduleScrollToCurrentChapter();
  }

  @override
  void dispose() {
    widget.provider.removeListener(_handleProviderChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleChapterTap(int index) async {
    if (widget.provider.hasPendingChapterNavigation) return;
    await widget.provider.jumpToChapter(index);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _scrollToCurrentChapter() {
    if (!mounted || !_scrollController.hasClients) return;
    final currentChapterIndex =
        widget.provider.pendingChapterNavigationIndex ??
        widget.provider.currentChapterIndex;
    if (currentChapterIndex == _lastScrolledChapterIndex) return;
    _lastScrolledChapterIndex = currentChapterIndex;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final viewportDimension = _scrollController.position.viewportDimension;
    final targetOffset =
        (currentChapterIndex * _tileExtent) -
        ((viewportDimension - _tileExtent) / 2);
    final safeOffset = targetOffset.clamp(0.0, maxExtent);
    _scrollController.jumpTo(safeOffset);
  }

  void _handleProviderChanged() {
    _scheduleScrollToCurrentChapter();
  }

  void _scheduleScrollToCurrentChapter() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToCurrentChapter(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final provider = widget.provider;
        return Drawer(
          child: Column(
            children: [
              AppBar(
                title: const Text('目錄'),
                automaticallyImplyLeading: false,
                elevation: 0,
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.chapters.length,
                  itemExtent: _tileExtent,
                  itemBuilder: (context, index) {
                    final isCurrentChapter =
                        provider.currentChapterIndex == index;
                    final isPendingChapter =
                        provider.pendingChapterNavigationIndex == index;
                    final tileColor =
                        isPendingChapter
                            ? Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.4)
                            : null;
                    return ListTile(
                      tileColor: tileColor,
                      enabled: !provider.hasPendingChapterNavigation,
                      leading:
                          isPendingChapter
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : null,
                      title: Text(
                        provider.displayChapterTitleAt(index),
                        style: TextStyle(
                          color: isCurrentChapter ? Colors.blue : null,
                          fontWeight: isCurrentChapter ? FontWeight.bold : null,
                        ),
                      ),
                      onTap: () => _handleChapterTap(index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
  int? _pendingChapterIndex;
  int _lastScrolledChapterIndex = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToCurrentChapter(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleChapterTap(int index) async {
    if (_pendingChapterIndex != null) return;
    setState(() {
      _pendingChapterIndex = index;
    });
    try {
      await widget.provider.jumpToChapter(index);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingChapterIndex = null;
        });
      }
    }
  }

  void _scrollToCurrentChapter() {
    if (!mounted || !_scrollController.hasClients) return;
    final currentChapterIndex = widget.provider.currentChapterIndex;
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

  @override
  Widget build(BuildContext context) {
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
                final isCurrentChapter = provider.currentChapterIndex == index;
                final isPendingChapter = _pendingChapterIndex == index;
                final tileColor =
                    isPendingChapter
                        ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.4)
                        : null;
                return ListTile(
                  tileColor: tileColor,
                  enabled: _pendingChapterIndex == null,
                  leading:
                      isPendingChapter
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
  }
}

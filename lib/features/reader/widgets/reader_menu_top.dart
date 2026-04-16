import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/change_chapter_source_sheet.dart';

class ReaderMenuTop extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onMoreMenu;

  const ReaderMenuTop({
    super.key,
    required this.provider,
    required this.onMoreMenu,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.book.name,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            if (provider.currentChapter != null)
              Text(
                provider.currentChapter!.title,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          // 核心功能：換源
          IconButton(
            icon: const Icon(Icons.find_replace, color: Colors.white),
            tooltip: '更換書源',
            onPressed: () => ChangeChapterSourceSheet.show(
              context, 
              provider.book, 
              provider.currentChapterIndex,
              provider.currentChapter?.title ?? ''
            ),
          ),
          // 書籤
          IconButton(
            icon: Icon(
              provider.isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
              color: provider.isBookmarked ? Colors.amber : Colors.white
            ),
            onPressed: () async {
              await provider.toggleBookmark();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(provider.isBookmarked ? '已加入書籤' : '已移除書籤'), duration: const Duration(seconds: 1))
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: onMoreMenu,
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/widgets/book_cover_widget.dart';

class BookshelfGridItem extends StatelessWidget {
  final Book book;
  final bool isBatchMode;
  final bool isSelected;
  final bool showLastUpdate;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BookshelfGridItem({
    super.key,
    required this.book,
    required this.isBatchMode,
    required this.isSelected,
    required this.showLastUpdate,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: BookCoverWidget(
                    bookName: book.name,
                    coverUrl: book.getDisplayCover(),
                  ),
                ),
                if (isBatchMode)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.blue : Colors.white70,
                    ),
                  ),
                if (book.isUpdate)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(4)),
                      ),
                      child: const Text('UP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (showLastUpdate && book.latestChapterTitle != null && book.latestChapterTitle!.isNotEmpty)
            Text(
              book.latestChapterTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}


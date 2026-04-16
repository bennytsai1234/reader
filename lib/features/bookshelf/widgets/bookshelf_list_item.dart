import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/widgets/book_cover_widget.dart';

class BookshelfListItem extends StatelessWidget {
  final Book book;
  final bool isBatchMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BookshelfListItem({
    super.key,
    required this.book,
    required this.isBatchMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Stack(
          children: [
            BookCoverWidget(
              bookName: book.name,
              coverUrl: book.getDisplayCover(),
            ),
            if (isBatchMode)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
      title: Text(book.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(
        '${(book.latestChapterTitle == null || book.latestChapterTitle!.isEmpty) ? "暫無進度" : book.latestChapterTitle}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: book.isUpdate ? const Icon(Icons.new_releases, color: Colors.red, size: 18) : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}


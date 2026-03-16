import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/widgets/book_cover_widget.dart';
import '../../book_detail/book_detail_page.dart';

class SearchResultItem extends StatelessWidget {
  final AggregatedSearchBook result;

  const SearchResultItem({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final book = result.book;
    return ListTile(
      leading: BookCoverWidget(
        coverUrl: book.coverUrl,
        bookName: book.name,
        author: book.author,
        width: 45,
        height: 60,
        borderRadius: BorderRadius.circular(4),
      ),
      title: Text(book.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            '${book.author ?? '未知'} · ${book.kind ?? '未知'} · ${book.wordCount ?? ''}',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            '最新: ${book.latestChapterTitle ?? '暫無'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
          ),
          const SizedBox(height: 2),
          Text(
            '來源: ${result.sources.join(', ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailPage(searchBook: result),
          ),
        );
      },
    );
  }
}


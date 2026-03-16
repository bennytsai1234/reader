import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:legado_reader/core/models/search_book.dart';
import '../../book_detail/book_detail_page.dart';

class ExploreBookItem extends StatelessWidget {
  final SearchBook book;

  const ExploreBookItem({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailPage(
              searchBook: AggregatedSearchBook(
                book: book,
                sources: [book.originName ?? '發現'],
              ),
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: book.coverUrl ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}


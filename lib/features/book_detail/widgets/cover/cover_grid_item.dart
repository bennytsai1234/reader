import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import '../../book_detail_provider.dart';

class CoverGridItem extends StatelessWidget {
  final AggregatedSearchBook result;

  const CoverGridItem({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isDefault = result.book.bookUrl == 'use_default_cover';
    return GestureDetector(
      onTap: () {
        context.read<BookDetailProvider>().updateCover(isDefault ? '' : (result.book.coverUrl ?? ''));
        Navigator.pop(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isDefault 
                ? Container(color: Colors.blue.withValues(alpha: 0.1), child: const Center(child: Icon(Icons.settings_backup_restore, color: Colors.blue, size: 32)))
                : CachedNetworkImage(
                    imageUrl: result.book.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(isDefault ? '恢復預設' : (result.book.originName ?? '未知來源'), style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}


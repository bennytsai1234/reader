import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/search_book.dart';

class ChangeSourceItem extends StatelessWidget {
  final SearchBook searchBook;
  final VoidCallback onTap;

  const ChangeSourceItem({super.key, required this.searchBook, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(searchBook.originName ?? '未知來源'),
      subtitle: Text(searchBook.latestChapterTitle ?? '無最新章節資訊', maxLines: 1),
      onTap: onTap,
    );
  }
}


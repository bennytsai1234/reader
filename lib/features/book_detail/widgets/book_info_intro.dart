import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/book.dart';

class BookInfoIntro extends StatelessWidget {
  final Book book;

  const BookInfoIntro({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text('簡介', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(book.intro ?? '暫無簡介', style: const TextStyle(fontSize: 15, height: 1.5)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


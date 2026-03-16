import 'package:flutter/material.dart';

class MangaTopBar extends StatelessWidget {
  final String bookName;
  final VoidCallback onBack;
  final VoidCallback onShowToc;

  const MangaTopBar({super.key, required this.bookName, required this.onBack, required this.onShowToc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      color: Colors.black.withValues(alpha: 0.85),
      child: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: onBack),
        title: Text(bookName, style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [IconButton(icon: const Icon(Icons.list, color: Colors.white), onPressed: onShowToc)],
      ),
    );
  }
}


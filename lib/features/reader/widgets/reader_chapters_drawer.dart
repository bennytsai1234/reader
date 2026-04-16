import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';

class ReaderChaptersDrawer extends StatelessWidget {
  final ReaderProvider provider;

  const ReaderChaptersDrawer({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
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
              itemCount: provider.chapters.length,
              itemBuilder: (context, index) {
                final isCur = provider.currentChapterIndex == index;
                return ListTile(
                  title: Text(
                    provider.displayChapterTitleAt(index),
                    style: TextStyle(
                      color: isCur ? Colors.blue : null,
                      fontWeight: isCur ? FontWeight.bold : null,
                    ),
                  ),
                  onTap: () {
                    provider.jumpToChapter(index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


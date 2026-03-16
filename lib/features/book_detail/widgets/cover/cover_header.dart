import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../change_cover_provider.dart';

class CoverHeader extends StatelessWidget {
  final String bookName;
  final String author;

  const CoverHeader({super.key, required this.bookName, required this.author});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChangeCoverProvider>(
      builder: (context, provider, child) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('更換封面', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(provider.isSearching ? Icons.stop_circle_outlined : Icons.refresh),
                color: provider.isSearching ? Colors.red : null,
                onPressed: () => provider.isSearching ? provider.stopSearch() : provider.search(bookName, author),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(alignment: Alignment.centerLeft, child: Text('搜尋關鍵字: $bookName $author', style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          ),
          if (provider.isSearching || provider.covers.isEmpty) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: provider.progress),
            const SizedBox(height: 4),
            Text(provider.isSearching ? '正在搜尋封面...' : (provider.covers.isEmpty ? '未找到封面' : '搜尋完成'), style: const TextStyle(fontSize: 11)),
          ],
        ],
      ),
    );
  }
}


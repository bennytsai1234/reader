import 'package:flutter/material.dart';
import '../search_provider.dart';

class SearchHistoryView extends StatelessWidget {
  final SearchProvider provider;
  final TextEditingController controller;
  final Function(String) onSearch;

  const SearchHistoryView({
    super.key,
    required this.provider,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.hotKeywords.isNotEmpty) ...[
          const Text('熱搜詞', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: provider.hotKeywords.map((h) {
              return ActionChip(
                label: Text(h, style: const TextStyle(color: Colors.blue)),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                onPressed: () {
                  controller.text = h;
                  onSearch(h);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (provider.history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('搜尋歷史', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: provider.clearHistory,
                child: const Text('清空'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: provider.history.map((h) => ActionChip(
              label: Text(h),
              onPressed: () {
                controller.text = h;
                onSearch(h);
              },
            )).toList(),
          ),
        ],
        if (provider.history.isEmpty && provider.hotKeywords.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.only(top: 40),
            child: Text('開始搜尋你想看的書吧', style: TextStyle(color: Colors.grey)),
          )),
      ],
    );
  }
}


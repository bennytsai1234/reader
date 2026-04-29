import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/book_detail/source/book_detail_change_source_provider.dart';

class BookDetailChangeSourceFilterBar extends StatelessWidget {
  const BookDetailChangeSourceFilterBar({
    super.key,
    required this.provider,
    required this.filterController,
  });

  final BookDetailChangeSourceProvider provider;
  final TextEditingController filterController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (provider.groups.length > 1)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: provider.groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final group = provider.groups[index];
                final isSelected = provider.selectedGroup == group;
                return FilterChip(
                  label: Text(
                    group,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) => provider.updateSelectedGroup(group),
                  selectedColor: Colors.blue,
                  showCheckmark: false,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: filterController,
            decoration: InputDecoration(
              hintText: '搜尋結果內篩選...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: provider.applyFilter,
          ),
        ),
      ],
    );
  }
}

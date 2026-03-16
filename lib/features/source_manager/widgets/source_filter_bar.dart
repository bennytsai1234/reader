import 'package:flutter/material.dart';
import 'package:legado_reader/features/source_manager/source_manager_provider.dart';

class SourceFilterBar extends StatelessWidget {
  final SourceManagerProvider provider;

  const SourceFilterBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.groups.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final group = provider.groups[index];
          final isSelected = provider.selectedGroup == group;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(group),
              selected: isSelected,
              onSelected: (selected) {
                provider.selectGroup(group);
              },
            ),
          );
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../explore_provider.dart';

class ExploreDashboard extends StatelessWidget {
  final ExploreProvider provider;
  final String? expandedSourceUrl;
  final Function(String?) onExpansionChanged;

  const ExploreDashboard({
    super.key,
    required this.provider,
    required this.expandedSourceUrl,
    required this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.sources.isEmpty) {
      return const Center(child: Text('目前無可用發現規則的書源'));
    }

    return ListView.builder(
      itemCount: provider.sources.length,
      itemBuilder: (context, index) {
        final source = provider.sources[index];
        final isExpanded = expandedSourceUrl == source.bookSourceUrl;

        return ExpansionTile(
          key: PageStorageKey(source.bookSourceUrl),
          title: Text(source.bookSourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(source.bookSourceGroup ?? '未分組', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            onExpansionChanged(expanded ? source.bookSourceUrl : null);
            if (expanded) {
              provider.setSource(source);
            }
          },
          children: [
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.filteredKinds.map((kind) {
                    return ActionChip(
                      label: Text(kind.title, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        provider.setKind(kind);
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}


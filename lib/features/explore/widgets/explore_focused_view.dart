import 'package:flutter/material.dart';
import '../explore_provider.dart';
import 'explore_book_item.dart';

class ExploreFocusedView extends StatelessWidget {
  final ExploreProvider provider;

  const ExploreFocusedView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: provider.isLoading && provider.books.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildResults(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Column(
        children: [
          ListTile(
            title: Text(provider.selectedSource!.bookSourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => provider.setSource(null),
            ),
          ),
          _buildConfigBar(),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildConfigBar() {
    if (provider.filteredKinds.isEmpty) return const SizedBox();
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: provider.filteredKinds.length,
        itemBuilder: (context, index) {
          final kind = provider.filteredKinds[index];
          final isSelected = provider.selectedKind == kind;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(kind.title),
              selected: isSelected,
              onSelected: (val) {
                if (val) provider.setKind(kind);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    if (provider.books.isEmpty && !provider.isLoading) {
      return const Center(child: Text('暫無內容'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.books.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.books.length) {
            provider.loadMore();
            return const Center(child: CircularProgressIndicator());
          }
          return ExploreBookItem(book: provider.books[index]);
        },
      ),
    );
  }
}


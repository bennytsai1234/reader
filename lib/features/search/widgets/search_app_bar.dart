import 'package:flutter/material.dart';
import '../search_provider.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final SearchProvider provider;
  final Function(String) onSearch;

  const SearchAppBar({
    super.key,
    required this.controller,
    required this.provider,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: '搜尋書名或作者',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white70),
        ),
        style: const TextStyle(color: Colors.white),
        textInputAction: TextInputAction.search,
        onSubmitted: onSearch,
      ),
      actions: [
        IconButton(
          icon: Icon(
            provider.isSearching ? Icons.stop_circle_outlined : Icons.search,
            color: provider.isSearching ? Colors.redAccent : null,
          ),
          onPressed: () {
            if (provider.isSearching) {
              provider.stopSearch();
            } else {
              onSearch(controller.text);
            }
          },
        ),
        PopupMenuButton<String>(
          tooltip: '搜尋設定',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'precision') {
              provider.togglePrecisionSearch();
            } else if (value.startsWith('group:')) {
              provider.setGroup(value.replaceFirst('group:', ''));
            }
          },
          itemBuilder: (context) {
            return [
              CheckedPopupMenuItem<String>(
                value: 'precision',
                checked: provider.precisionSearch,
                child: const Text('精準搜尋'),
              ),
              const PopupMenuDivider(),
              ...provider.sourceGroups.map((group) {
                return CheckedPopupMenuItem<String>(
                  value: 'group:$group',
                  checked: provider.selectedGroup == group,
                  child: Text(group),
                );
              }),
            ];
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


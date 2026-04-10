import 'package:flutter/material.dart';
import '../search_provider.dart';

/// SearchAppBar - 搜尋頁面頂部欄
/// (對標 Legado SearchActivity 的 TitleBar + SearchView)
///
/// 功能：
/// - 搜尋輸入框
/// - 搜尋範圍顯示按鈕（點擊觸發 onScopePressed）
/// - 開始/停止搜尋按鈕
/// - 精準搜尋切換（PopupMenu）
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final SearchProvider provider;
  final Function(String) onSearch;
  final VoidCallback? onScopePressed;

  const SearchAppBar({
    super.key,
    required this.controller,
    required this.provider,
    required this.onSearch,
    this.onScopePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scopeDisplay = provider.scopeLoaded ? provider.searchScope.display : '載入中...';

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '搜尋書名或作者',
                border: InputBorder.none,
                hintStyle: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              style: TextStyle(color: theme.colorScheme.onPrimary),
              textInputAction: TextInputAction.search,
              onSubmitted: onSearch,
            ),
          ),
        ],
      ),
      actions: [
        // 搜尋範圍按鈕 (對標 Legado SearchActivity 的 tvSearchScope)
        InkWell(
          onTap: onScopePressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scopeDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: provider.searchScope.isAll
                        ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                        : theme.colorScheme.onPrimary,
                    fontWeight: provider.searchScope.isAll ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
        // 搜尋/停止按鈕
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
        // 設定選單（精準搜尋）
        PopupMenuButton<String>(
          tooltip: '搜尋設定',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'precision') {
              provider.togglePrecisionSearch();
            }
          },
          itemBuilder: (context) {
            return [
              CheckedPopupMenuItem<String>(
                value: 'precision',
                checked: provider.precisionSearch,
                child: const Text('精準搜尋'),
              ),
            ];
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

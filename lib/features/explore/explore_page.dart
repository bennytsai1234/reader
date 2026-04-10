import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'explore_provider.dart';
import 'explore_show_page.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/source/explore_kind.dart';
import 'package:legado_reader/features/source_manager/source_editor_page.dart';
import 'package:legado_reader/features/search/search_page.dart';

/// ExplorePage - 發現主頁面
/// (對標 Android ExploreFragment + ExploreAdapter)
///
/// 顯示所有啟用探索的書源列表，點擊展開分類標籤，
/// 點擊分類標籤跳轉 ExploreShowPage。
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreProvider(),
      child: const _ExplorePageContent(),
    );
  }
}

class _ExplorePageContent extends StatefulWidget {
  const _ExplorePageContent();

  @override
  State<_ExplorePageContent> createState() => _ExplorePageContentState();
}

class _ExplorePageContentState extends State<_ExplorePageContent> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('發現'),
        actions: [
          // 分組過濾菜單 (對標 Android menu_group)
          if (provider.groups.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: '按分組篩選',
              onSelected: (group) => provider.setGroupFilter(group),
              itemBuilder: (ctx) {
                return provider.groups.map((g) {
                  final isSelected = provider.selectedGroup == g;
                  return PopupMenuItem<String>(
                    value: g,
                    child: Row(
                      children: [
                        if (isSelected)
                          Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(g),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索欄 (對標 Android SearchView)
          _buildSearchBar(provider, theme),
          // 當前篩選提示
          if (provider.selectedGroup != null)
            _buildGroupFilterChip(provider, theme),
          // 書源列表
          Expanded(child: _buildSourceList(provider, theme)),
        ],
      ),
    );
  }

  /// 搜索欄 (對標 Android initSearchView)
  Widget _buildSearchBar(ExploreProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索發現書源',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        style: const TextStyle(fontSize: 14),
        onChanged: (value) => provider.setSearchQuery(value),
      ),
    );
  }

  /// 分組篩選提示條
  Widget _buildGroupFilterChip(ExploreProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            '分組: ${provider.selectedGroup}',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => provider.setGroupFilter(null),
            child: Icon(Icons.close, size: 14, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  /// 書源列表 (對標 Android rvFind RecyclerView)
  Widget _buildSourceList(ExploreProvider provider, ThemeData theme) {
    if (provider.isEmpty && provider.searchQuery.isEmpty && provider.selectedGroup == null) {
      return const Center(
        child: Text('目前無可用發現規則的書源', style: TextStyle(color: Colors.grey)),
      );
    }

    if (provider.isEmpty) {
      return Center(
        child: Text(
          '找不到符合條件的書源',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: provider.sources.length,
      itemBuilder: (context, index) {
        final source = provider.sources[index];
        final isExpanded = provider.expandedIndex == index;
        return _buildSourceItem(provider, source, index, isExpanded, theme);
      },
    );
  }

  /// 書源項目 (對標 Android ItemFindBookBinding)
  Widget _buildSourceItem(
    ExploreProvider provider,
    BookSource source,
    int index,
    bool isExpanded,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 書源標題行 (對標 Android ll_title)
        InkWell(
          onTap: () {
            provider.toggleExpand(index);
            // 自動滾動到展開的位置
            if (!isExpanded) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    index * 50.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          },
          onLongPress: () => _showSourceMenu(context, provider, source),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    source.bookSourceName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // 載入動畫 (對標 Android rotateLoading)
                if (isExpanded && provider.isLoadingKinds)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 4),
                // 展開箭頭 (對標 Android ivStatus)
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        // 分類標籤 (對標 Android FlexboxLayout)
        if (isExpanded && !provider.isLoadingKinds && provider.expandedKinds.isNotEmpty)
          _buildKindTags(provider, source, theme),
        // 底部分隔線
        if (index < provider.sources.length - 1)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  /// 分類標籤 Wrap (對標 Android FlexboxLayout + item_fillet_text)
  Widget _buildKindTags(ExploreProvider provider, BookSource source, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: provider.expandedKinds.map((kind) {
          final isError = kind.title.startsWith('ERROR:');
          return InkWell(
            onTap: () {
              if (isError || kind.url == null || kind.url!.isEmpty) return;
              _navigateToExploreShow(source, kind);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isError
                    ? Colors.red.withValues(alpha: 0.1)
                    : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isError
                      ? Colors.red.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                kind.title,
                style: TextStyle(
                  fontSize: 12,
                  color: isError
                      ? Colors.red
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 跳轉到探索結果頁面 (對標 Android openExplore)
  void _navigateToExploreShow(BookSource source, ExploreKind kind) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreShowPage(
          sourceUrl: source.bookSourceUrl,
          exploreUrl: kind.url!,
          exploreName: kind.title,
        ),
      ),
    );
  }

  /// 長按書源選單 (對標 Android showMenu / explore_item.xml)
  void _showSourceMenu(BuildContext context, ExploreProvider provider, BookSource source) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                source.bookSourceName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            // 編輯 (對標 Android menu_edit)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編輯'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SourceEditorPage(source: source),
                  ),
                );
              },
            ),
            // 置頂 (對標 Android menu_top)
            ListTile(
              leading: const Icon(Icons.vertical_align_top),
              title: const Text('置頂'),
              onTap: () {
                Navigator.pop(ctx);
                provider.topSource(source);
              },
            ),
            // 搜索 (對標 Android menu_search)
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('搜索'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchPage(),
                  ),
                );
              },
            ),
            // 刷新 (對標 Android menu_refresh)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('刷新分類'),
              onTap: () {
                Navigator.pop(ctx);
                provider.refreshKindsCache(source);
              },
            ),
            // 刪除 (對標 Android menu_del)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('刪除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, provider, source);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 確認刪除 (對標 Android alert R.string.draw)
  void _confirmDelete(BuildContext context, ExploreProvider provider, BookSource source) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認'),
        content: Text('確定刪除「${source.bookSourceName}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteSource(source);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'rss_source_provider.dart';
import 'rss_article_page.dart';
import 'rss_source_editor_page.dart';
import 'package:legado_reader/core/models/rss_source.dart';

class RssSourcePage extends StatelessWidget {
  const RssSourcePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RssSourceProvider(),
      child: Consumer<RssSourceProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('RSS 訂閱'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddDialog(context, provider),
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.sources.length,
                    itemBuilder: (context, index) {
                      final source = provider.sources[index];
                      return _buildSourceItem(context, provider, source);
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSourceItem(BuildContext context, RssSourceProvider provider, RssSource source) {
    return ListTile(
      leading: source.sourceIcon.isNotEmpty 
        ? CachedNetworkImage(imageUrl: source.sourceIcon, width: 40, height: 40, errorWidget: (_,__,___) => const Icon(Icons.rss_feed))
        : const Icon(Icons.rss_feed),
      title: Text(source.sourceName),
      subtitle: Text(source.sourceUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: source.enabled,
            onChanged: (_) => provider.toggleEnabled(source),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RssSourceEditorPage(source: source)),
            ).then((_) => provider.loadSources()),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RssArticlePage(source: source)),
        );
      },
      onLongPress: () => _showDeleteDialog(context, provider, source),
    );
  }

  void _showAddDialog(BuildContext context, RssSourceProvider provider) {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增 RSS 來源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: '輸入 RSS 來源 JSON URL'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RssSourceEditorPage()),
                ).then((_) => provider.loadSources());
              },
              child: const Text('手動建立來源'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final count = await provider.importFromUrl(urlController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功匯入 $count 個來源')));
              }
            },
            child: const Text('匯入'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, RssSourceProvider provider, RssSource source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除來源'),
        content: Text('確定要刪除「${source.sourceName}」嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.deleteSource(source.sourceUrl);
              Navigator.pop(context);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


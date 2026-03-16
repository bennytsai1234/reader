import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/services/export_book_service.dart';
import 'cache_manager_provider.dart';

class CacheManagerPage extends StatelessWidget {
  final Book book;

  const CacheManagerPage({super.key, required this.book});

  Future<void> _exportBook(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    const double progress = 0;
    
    // 顯示進度彈窗 (原 Android 服務通知)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('正在匯出書籍'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('正在處理: ${book.name}'),
                const SizedBox(height: 16),
                const LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text('${(progress * 100).toStringAsFixed(1)}%'),
              ],
            ),
          );
        },
      ),
    );

    try {
      await ExportBookService().exportToTxt(book, onProgress: (p) {
        if (context.mounted) {
          // 透過彈窗內部的 setState 更新進度
          // 這裡需要透過一個變數或 Notifier，我們改用 Notifier 模式更穩健
        }
      });
      if (context.mounted) Navigator.pop(context); // 關閉進度彈窗
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('匯出成功')));
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('匯出失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CacheManagerProvider(book),
      child: Consumer<CacheManagerProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${book.name} - 快取管理'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.output_outlined),
                  tooltip: '匯出書籍',
                  onPressed: () => _exportBook(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: '清除快取',
                  onPressed: () => _showClearConfirm(context, provider),
                ),
              ],
            ),
            body: Column(
              children: [
                if (provider.downloadService.isDownloading)
                  _buildProgressHeader(provider),
                _buildActionButtons(context, provider),
                const Divider(height: 1),
                Expanded(child: _buildChapterList(provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(CacheManagerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(provider.downloadService.isPaused ? '下載已暫停' : '正在下載中...', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${(provider.downloadService.progress * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: provider.downloadService.progress),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(provider.downloadService.isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: provider.downloadService.togglePause,
                label: Text(provider.downloadService.isPaused ? '恢復下載' : '暫停下載'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: provider.downloadService.cancelDownloads,
                child: const Text('停止下載'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CacheManagerProvider provider) {
    final total = provider.chapters.length;
    final cached = provider.cachedIndices.length;
    final percent = total > 0 ? (cached * 100 / total).toStringAsFixed(1) : '0';
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // 快取統計
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.storage, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '已快取 $cached / $total 章 ($percent%)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 18),
                  onPressed: () => provider.downloadChapters(0, total),
                  label: const Text('下載全部'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                  onPressed: () => provider.downloadUncached(),
                  label: const Text('下載未快取'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList(CacheManagerProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: provider.chapters.length,
      itemBuilder: (context, index) {
        final chapter = provider.chapters[index];
        final isCached = provider.cachedIndices.contains(index);
        return ListTile(
          dense: true,
          title: Text(chapter.title),
          trailing: isCached 
            ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
            : const Icon(Icons.download_for_offline, color: Colors.grey, size: 16),
          onTap: isCached ? null : () => provider.downloadChapters(index, index + 1),
        );
      },
    );
  }

  void _showClearConfirm(BuildContext context, CacheManagerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認清除'),
        content: const Text('確定要清除這本書的所有快取內容嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.clearCache();
              Navigator.pop(context);
            },
            child: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'global_cache_provider.dart';

class GlobalCachePage extends StatelessWidget {
  const GlobalCachePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GlobalCacheProvider(),
      child: Consumer<GlobalCacheProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('儲存空間管理'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.loadCacheInfo,
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _buildHeader(provider),
                      Expanded(
                        child: ListView.separated(
                          itemCount: provider.cacheItems.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = provider.cacheItems[index];
                            return ListTile(
                              title: Text(item.label),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.sizeFormatted,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _confirmClear(context, item),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(GlobalCacheProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      color: Colors.blue.withValues(alpha: 0.05),
      child: Column(
        children: [
          const Icon(Icons.storage, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('已佔用總空間', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            _formatSize(provider.totalSize),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _confirmClear(BuildContext context, GlobalCacheInfo item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理確認'),
        content: Text('確定要清理 "${item.label}" 嗎？\n這將移除本地緩存的資料。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              item.onClear();
              Navigator.pop(context);
            },
            child: const Text('確定清理', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


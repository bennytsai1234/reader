import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/read_record.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'read_record_provider.dart';

class ReadRecordPage extends StatefulWidget {
  const ReadRecordPage({super.key});

  @override
  State<ReadRecordPage> createState() => _ReadRecordPageState();
}

class _ReadRecordPageState extends State<ReadRecordPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReadRecordProvider(),
      child: Consumer<ReadRecordProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: _isSearching 
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '搜尋書籍',
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => provider.search(val),
                  )
                : const Text('閱讀紀錄'),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        provider.search('');
                      }
                    });
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                _buildSummaryHeader(context, provider),
                const Divider(height: 1),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.records.isEmpty
                          ? const Center(child: Text('暫無紀錄'))
                          : ListView.separated(
                              itemCount: provider.records.length,
                              separatorBuilder: (ctx, i) => const Divider(height: 1),
                              itemBuilder: (ctx, i) => _buildRecordItem(context, provider, provider.records[i]),
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, ReadRecordProvider p) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '共閱讀了 ${p.records.length} 本書',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '累計時長: ${p.formatDuration(p.totalTime)}',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showClearAllConfirm(context, p),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, ReadRecordProvider p, ReadRecord record) {
    final lastRead = DateTime.fromMillisecondsSinceEpoch(record.lastRead);
    final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(lastRead);

    return ListTile(
      title: Text(record.bookName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('累計時長: ${p.formatDuration(record.readTime)}'),
          Text('最後閱讀: $timeStr', style: const TextStyle(fontSize: 12)),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        onPressed: () => p.deleteRecord(record.bookName),
      ),
    );
  }

  void _showClearAllConfirm(BuildContext context, ReadRecordProvider p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認清空'),
        content: const Text('是否清空所有閱讀紀錄？此操作不可撤銷。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              p.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/features/read_record/read_record_provider.dart';

class ReadRecordPage extends StatelessWidget {
  const ReadRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReadRecordProvider(),
      child: Consumer<ReadRecordProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('閱讀統計')),
            body: provider.records.isEmpty
                ? const Center(child: Text('目前尚未有閱讀記錄'))
                : ListView.builder(
                    itemCount: provider.records.length,
                    itemBuilder: (context, index) {
                      final record = provider.records[index];
                      final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(record.lastRead),
                      );
                      return ListTile(
                        title: Text(record.bookName),
                        subtitle: Text('累計閱讀: ${_formatDuration(record.readTime)}'),
                        trailing: Text(timeStr,
                            style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds 秒';
    if (seconds < 3600) return '${seconds ~/ 60} 分鐘';
    return '${(seconds / 3600).toStringAsFixed(1)} 小時';
  }
}

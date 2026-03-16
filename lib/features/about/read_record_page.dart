import 'package:legado_reader/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:legado_reader/core/database/dao/read_record_dao.dart';
import 'package:legado_reader/core/models/read_record.dart';

class ReadRecordPage extends StatelessWidget {
  const ReadRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('閱讀統計'),
      ),
      body: FutureBuilder<List<ReadRecord>>(
        future: getIt<ReadRecordDao>().getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('目前尚未有閱讀記錄'));
          }
          final records = snapshot.data!;
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(
                DateTime.fromMillisecondsSinceEpoch(record.lastRead),
              );
              return ListTile(
                title: Text(record.bookName),
                subtitle: Text('累計閱讀: ${_formatDuration(record.readTime)}'),
                trailing: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              );
            },
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


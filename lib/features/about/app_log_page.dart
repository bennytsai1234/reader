import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';

class AppLogPage extends StatefulWidget {
  const AppLogPage({super.key});

  @override
  State<AppLogPage> createState() => _AppLogPageState();
}

class _AppLogPageState extends State<AppLogPage> {
  @override
  Widget build(BuildContext context) {
    final logs = AppLog.logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('應用程式日誌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() {
                AppLog.clear();
              });
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('目前尚無日誌'))
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                final timeStr = DateFormat('HH:mm:ss').format(
                  DateTime.fromMillisecondsSinceEpoch(log.timestamp),
                );
                return ListTile(
                  dense: true,
                  title: Text(log.message, style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  )),
                  subtitle: Text('$timeStr ${log.error ?? ""}', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
    );
  }
}


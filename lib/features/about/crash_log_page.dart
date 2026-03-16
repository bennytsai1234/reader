import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:legado_reader/core/services/crash_handler.dart';

class CrashLogPage extends StatefulWidget {
  const CrashLogPage({super.key});

  @override
  State<CrashLogPage> createState() => _CrashLogPageState();
}

class _CrashLogPageState extends State<CrashLogPage> {
  String _logs = '正在載入...';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await CrashHandler.readLogs();
    if (mounted) setState(() => _logs = logs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('崩潰日誌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _logs));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已複製至剪貼簿')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: () async {
              await CrashHandler.clearLogs();
              _loadLogs();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          _logs,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}


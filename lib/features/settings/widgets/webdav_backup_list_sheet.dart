import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:legado_reader/core/services/webdav_service.dart';
import 'package:legado_reader/core/utils/logger.dart';

class WebDavBackupListSheet extends StatefulWidget {
  const WebDavBackupListSheet({super.key});

  @override
  State<WebDavBackupListSheet> createState() => _WebDavBackupListSheetState();
}

class _WebDavBackupListSheetState extends State<WebDavBackupListSheet> {
  bool _isLoading = true;
  List<dynamic> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final list = await WebDavService().listBackups();
      if (mounted) {
        setState(() {
          _backups = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.e('載入備份列表失敗: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _backups.isEmpty
                    ? const Center(child: Text('雲端暫無備份檔案'))
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('雲端備份列表', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadBackups),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      itemCount: _backups.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final file = _backups[i];
        final name = file.name ?? '未知備份';
        final size = (file.size ?? 0) / 1024 / 1024; // MB
        final mTime = file.mTime != null 
            ? DateFormat('yyyy-MM-dd HH:mm').format(file.mTime!)
            : '未知時間';

        return ListTile(
          leading: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
          title: Text(name, style: const TextStyle(fontSize: 14)),
          subtitle: Text('$mTime · ${size.toStringAsFixed(2)} MB', style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.settings_backup_restore, size: 20),
          onTap: () => _showRestoreConfirm(context, name),
        );
      },
    );
  }

  void _showRestoreConfirm(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認還原'),
        content: Text('確定要從備份 [$fileName] 還原嗎？這將覆蓋目前所有的書架、書源與設定資料。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _performRestore(fileName);
            },
            child: const Text('開始還原'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(String fileName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final success = await WebDavService().restoreBackup(fileName);

    if (mounted) {
      Navigator.pop(context); // 關閉 Loading
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('還原成功！請重啟應用程式以載入新配置。')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('還原失敗，請檢查網路或檔案是否損壞。')),
        );
      }
    }
  }
}

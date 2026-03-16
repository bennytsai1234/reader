import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_provider.dart';
import 'package:legado_reader/core/services/webdav_service.dart';
import 'widgets/webdav_backup_list_sheet.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final TextEditingController _webdavUrlController = TextEditingController();
  final TextEditingController _webdavUserController = TextEditingController();
  final TextEditingController _webdavPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _webdavUrlController.text = settings.webdavUrl;
    _webdavUserController.text = settings.webdavUser;
    _webdavPasswordController.text = settings.webdavPassword;
  }

  @override
  void dispose() {
    _webdavUrlController.dispose();
    _webdavUserController.dispose();
    _webdavPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('備份與還原')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionTitle('WebDAV 設定'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _webdavUrlController,
                      decoration: const InputDecoration(
                        labelText: 'WebDAV 伺服器網址',
                        hintText: '例如: https://dav.jianguoyun.com/dav/',
                      ),
                      onChanged: (v) => _saveWebdavAccount(settings),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _webdavUserController,
                      decoration: const InputDecoration(labelText: 'WebDAV 帳號'),
                      onChanged: (v) => _saveWebdavAccount(settings),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _webdavPasswordController,
                      decoration: const InputDecoration(labelText: 'WebDAV 密碼/授權碼'),
                      obscureText: true,
                      onChanged: (v) => _saveWebdavAccount(settings),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _testWebdavConnection(settings),
                      icon: const Icon(Icons.sync_alt),
                      label: const Text('測試連線並同步'),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('子目錄 (Sub Directory)'),
                subtitle: Text(settings.webdavSubDir.isEmpty ? '根目錄' : settings.webdavSubDir),
                onTap: () => _showEditDialog(context, '子目錄', settings.webdavSubDir, (v) => settings.setWebdavSubDir(v)),
              ),
              ListTile(
                title: const Text('裝置名稱 (Device Name)'),
                subtitle: Text(settings.deviceName.isEmpty ? '預設' : settings.deviceName),
                onTap: () => _showEditDialog(context, '裝置名稱', settings.deviceName, (v) => settings.setDeviceName(v)),
              ),
              SwitchListTile(
                title: const Text('同步書籍進度'),
                subtitle: const Text('開啟後會自動將閱讀進度同步到 WebDAV'),
                value: settings.syncBookProgress,
                onChanged: (v) => settings.setSyncBookProgress(v),
              ),
              ListTile(
                title: const Text('雲端備份管理'),
                subtitle: const Text('查看、下載或還原 WebDAV 上的備份檔案'),
                leading: const Icon(Icons.cloud_sync_outlined),
                onTap: () => _showWebDavBackupList(context),
              ),

              const Divider(),
              _buildSectionTitle('本地備份與還原'),
              ListTile(
                title: const Text('選擇本地備份目錄'),
                subtitle: const Text('設定或變更本地配置備份的資料夾'),
                leading: const Icon(Icons.folder_open),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('手動備份 (WebDAV / Local)'),
                subtitle: const Text('將目前所有書架與配置進行備份'),
                leading: const Icon(Icons.backup_outlined),
                onTap: () async {
                  await WebDavService().uploadFullBackup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('全量備份已上傳至 WebDAV')));
                  }
                },
              ),
              ListTile(
                title: const Text('手動還原 (本地文件)'),
                subtitle: const Text('從本地備份檔恢復資料'),
                leading: const Icon(Icons.restore),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    // 還原邏輯
                  }
                },
              ),
              SwitchListTile(
                title: const Text('僅保留最新備份'),
                value: settings.onlyLatestBackup,
                onChanged: (v) => settings.setOnlyLatestBackup(v),
              ),
              SwitchListTile(
                title: const Text('自動檢查新備份'),
                value: settings.autoCheckNewBackup,
                onChanged: (v) => settings.setAutoCheckNewBackup(v),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
    );
  }

  void _saveWebdavAccount(SettingsProvider settings) {
    settings.updateWebDav(
      url: _webdavUrlController.text,
      user: _webdavUserController.text,
      password: _webdavPasswordController.text,
    );
  }

  Future<void> _testWebdavConnection(SettingsProvider settings) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await WebDavService().checkAndInit();
    if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text(success ? 'WebDAV 連線測試成功！' : '連線失敗，請檢查設定')));
    }
  }

  void _showWebDavBackupList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const WebDavBackupListSheet(),
    );
  }

  void _showEditDialog(BuildContext context, String title, String current, Function(String) onSave) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('修改 $title'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              onSave(ctrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('功能開發中')));
  }
}

import 'package:flutter/material.dart';
import '../source_manager_provider.dart';

class SourceBatchToolbar extends StatelessWidget {
  final SourceManagerProvider provider;
  final VoidCallback onGroup;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const SourceBatchToolbar({
    super.key,
    required this.provider,
    required this.onGroup,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).cardColor,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildItem(context, Icons.drive_file_move_outlined, '移動', onGroup),
          _buildItem(context, Icons.share_outlined, '分享', () => provider.shareSelectedSources()),
          _buildItem(context, Icons.copy_all_outlined, '複製', onExport),
          _buildItem(context, Icons.playlist_add_check, '校驗', () => provider.checkSelectedSources()),
          _buildItem(context, Icons.delete_outline, '刪除', onDelete, isDanger: true),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDanger = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isDanger ? Colors.red : null),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isDanger ? Colors.red : null)),
          ],
        ),
      ),
    );
  }
}

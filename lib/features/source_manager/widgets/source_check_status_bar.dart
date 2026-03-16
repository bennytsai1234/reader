import 'package:flutter/material.dart';
import '../source_manager_provider.dart';

class SourceCheckStatusBar extends StatelessWidget {
  final SourceManagerProvider provider;
  final VoidCallback onTap;

  const SourceCheckStatusBar({super.key, required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.blue.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Expanded(child: Text('正在校驗 (${provider.checkService.currentCount}/${provider.checkService.totalCount}): ${provider.checkService.statusMsg}', style: const TextStyle(fontSize: 12))),
            const Icon(Icons.chevron_right, size: 16, color: Colors.blue),
            TextButton(onPressed: provider.checkService.cancel, child: const Text('取消')),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../reader_provider.dart';

class ReaderTopMenu extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onMore;

  const ReaderTopMenu({super.key, required this.provider, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -120,
      left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppBar(context),
            _buildAdditionInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        Expanded(
          child: Text(
            provider.book.name,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: onMore),
      ],
    );
  }

  /// 頂部附加資訊 (對標 Android title_bar_addition)
  Widget _buildAdditionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentChapterTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.currentChapterUrl.isNotEmpty)
                  Text(
                    provider.currentChapterUrl,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildSourceTag(context),
        ],
      ),
    );
  }

  /// 書源標籤 (對標 Android tv_source_action)
  Widget _buildSourceTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        provider.book.originName,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

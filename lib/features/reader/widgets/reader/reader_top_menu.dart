import 'package:flutter/material.dart';
import '../../reader_provider.dart';
import 'reader_menu_palette.dart';

class ReaderTopMenu extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const ReaderTopMenu({
    super.key,
    required this.provider,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -120,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: ReaderMenuPalette.background,
          border: Border(bottom: BorderSide(color: ReaderMenuPalette.outline)),
          boxShadow: [
            BoxShadow(
              color: ReaderMenuPalette.scrim,
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildAppBar(context), _buildAdditionInfo(context)],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: ReaderMenuPalette.foreground,
          ),
          onPressed: onBack,
        ),
        Expanded(
          child: Text(
            provider.book.name,
            style: const TextStyle(
              color: ReaderMenuPalette.foreground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: ReaderMenuPalette.foreground,
          ),
          onPressed: onMore,
        ),
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
                  style: const TextStyle(
                    color: ReaderMenuPalette.mutedForeground,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.currentChapterUrl.isNotEmpty)
                  Text(
                    provider.currentChapterUrl,
                    style: const TextStyle(
                      color: ReaderMenuPalette.mutedForeground,
                      fontSize: 10,
                    ),
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
        color: ReaderMenuPalette.accentMuted,
        border: Border.all(color: ReaderMenuPalette.accent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        provider.book.originName,
        style: const TextStyle(
          color: ReaderMenuPalette.foreground,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

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
    final menuStyle = ReaderMenuStyle.resolve(
      context: context,
      followPageStyle: provider.readBarStyleFollowPage,
      pageBackgroundColor: provider.currentTheme.backgroundColor,
      pageTextColor: provider.currentTheme.textColor,
    );
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !provider.showControls,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          offset: provider.showControls ? Offset.zero : const Offset(0, -1.15),
          child: Container(
            decoration: BoxDecoration(
              color: menuStyle.background,
              border: Border(bottom: BorderSide(color: menuStyle.outline)),
              boxShadow: [
                BoxShadow(
                  color: menuStyle.scrim,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAppBar(context, menuStyle),
                if (provider.showReadTitleAddition)
                  _buildAdditionInfo(context, menuStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ReaderMenuStyle menuStyle) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: menuStyle.foreground),
          onPressed: onBack,
        ),
        Expanded(
          child: Text(
            provider.book.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ).copyWith(color: menuStyle.foreground),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: menuStyle.foreground),
          onPressed: onMore,
        ),
      ],
    );
  }

  /// 頂部附加資訊 (對標 Android title_bar_addition)
  Widget _buildAdditionInfo(BuildContext context, ReaderMenuStyle menuStyle) {
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
                  style: TextStyle(
                    color: menuStyle.mutedForeground,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.currentChapterUrl.isNotEmpty)
                  Text(
                    provider.currentChapterUrl,
                    style: TextStyle(
                      color: menuStyle.mutedForeground,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildSourceTag(context, menuStyle),
        ],
      ),
    );
  }

  /// 書源標籤 (對標 Android tv_source_action)
  Widget _buildSourceTag(BuildContext context, ReaderMenuStyle menuStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: menuStyle.accentMuted,
        border: Border.all(color: menuStyle.accent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        provider.book.originName,
        style: TextStyle(
          color: menuStyle.foreground,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

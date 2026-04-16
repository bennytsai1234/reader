import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../reader_provider.dart';
import 'package:inkpage_reader/features/search/search_page.dart';

/// ReaderSelectionMenu - 閱讀器自定義文字選中選單 (對標 Android popup_action_menu.xml)
class ReaderSelectionMenu extends StatelessWidget {
  final TextSelection selection;
  final String selectedText;
  final ReaderProvider provider;
  final VoidCallback onClear;

  const ReaderSelectionMenu({
    super.key,
    required this.selection,
    required this.selectedText,
    required this.provider,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).canvasColor,
      child: IntrinsicWidth(
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAction(context, Icons.copy, '複製', () {
                Clipboard.setData(ClipboardData(text: selectedText));
                onClear();
              }),
              _buildDivider(),
              _buildAction(context, Icons.search, '搜尋', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(initialQuery: selectedText)));
                onClear();
              }),
              _buildDivider(),
              _buildAction(context, Icons.translate, '翻譯', () {
                // 跳轉翻譯邏輯
                onClear();
              }),
              _buildDivider(),
              _buildAction(context, Icons.edit_note, '筆記', () {
                provider.addBookmark(content: selectedText);
                onClear();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return VerticalDivider(indent: 10, endIndent: 10, width: 1, color: Colors.grey.withValues(alpha: 0.3));
  }
}

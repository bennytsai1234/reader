import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'provider/change_source_provider.dart';
import 'widgets/change_source_filter_bar.dart';
import 'widgets/change_source_item.dart';
import 'reader_provider.dart';
import 'reader_page.dart';
import 'audio_player_page.dart';

class ChangeChapterSourceSheet extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  final String chapterTitle;

  const ChangeChapterSourceSheet({super.key, required this.book, required this.chapterIndex, required this.chapterTitle});

  static void show(BuildContext context, Book book, int chapterIndex, String chapterTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeChapterSourceSheet(book: book, chapterIndex: chapterIndex, chapterTitle: chapterTitle),
    );
  }

  @override
  State<ChangeChapterSourceSheet> createState() => _ChangeChapterSourceSheetState();
}

class _ChangeChapterSourceSheetState extends State<ChangeChapterSourceSheet> {
  final TextEditingController _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChangeSourceProvider(widget.book),
      child: Consumer<ChangeSourceProvider>(
        builder: (context, provider, child) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(provider),
                ChangeSourceFilterBar(provider: provider, filterController: _filterController),
                if (provider.isSearching) const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(provider.status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
                Expanded(child: _buildSourceList(provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))));
  }

  Widget _buildHeader(ChangeSourceProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('單章換源', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('目標章節: ${widget.chapterTitle}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(icon: Icon(provider.checkAuthor ? Icons.person : Icons.person_off), onPressed: provider.toggleCheckAuthor),
          IconButton(icon: const Icon(Icons.refresh), onPressed: provider.startSearch),
        ],
      ),
    );
  }

  Widget _buildSourceList(ChangeSourceProvider provider) {
    if (provider.filteredResults.isEmpty && !provider.isSearching) {
      return const Center(child: Text('無搜尋結果'));
    }
    return ListView.separated(
      itemCount: provider.filteredResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => ChangeSourceItem(
        searchBook: provider.filteredResults[index],
        onTap: () => _handleSourceSelected(context, provider, provider.filteredResults[index]),
      ),
    );
  }

  Future<void> _handleSourceSelected(BuildContext context, ChangeSourceProvider provider, SearchBook searchBook) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final readerProvider = context.read<ReaderProvider>();

    final sources = await provider.sourceDao.getAll();
    if (!context.mounted) return;
    
    final source = sources.cast<BookSource?>().firstWhere((s) => s?.bookSourceUrl == searchBook.origin, orElse: () => null);
    if (source == null) {
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

    try {
      final tempBook = searchBook.toBook();
      final chapters = await provider.service.getChapterList(source, tempBook);
      var targetIndex = chapters.indexWhere((c) => c.title == widget.chapterTitle);
      if (targetIndex == -1 && widget.chapterIndex < chapters.length) {
        targetIndex = widget.chapterIndex;
      }

      if (!mounted) return;
      
      if (targetIndex != -1) {
        final content = await provider.service.getContent(source, tempBook, chapters[targetIndex]);
        if (!mounted) return;
        
        // Pop loading dialog
        nav.pop();
        
        if (tempBook.type != widget.book.type) {
          if (!context.mounted) return;
          _showMigrationDialog(context, widget.book.migrateTo(tempBook, chapters));
        } else {
          readerProvider.replaceChapterSource(widget.chapterIndex, source, content);
          // Pop sheet
          nav.pop();
        }
      } else {
        if (mounted) {
          nav.pop();
          messenger.showSnackBar(const SnackBar(content: Text('找不到對應章節')));
        }
      }
    } catch (e) {
      if (mounted) {
        nav.pop();
        messenger.showSnackBar(SnackBar(content: Text('換源失敗: $e')));
      }
    }
  }

  void _showMigrationDialog(BuildContext context, Book newBook) {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('書籍類型變更'),
        content: Text('偵測到新來源為${newBook.type == 2 ? "有聲" : "文本"}類型，是否遷移？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              nav.pop();
              nav.pushReplacement(
                MaterialPageRoute(builder: (_) => newBook.type == 2 ? AudioPlayerPage(book: newBook, chapterIndex: newBook.durChapterIndex) : ReaderPage(book: newBook)),
              );
            },
            child: const Text('遷移並跳轉'),
          ),
        ],
      ),
    );
  }
}


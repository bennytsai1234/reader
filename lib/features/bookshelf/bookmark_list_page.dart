import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/features/reader/reader_page.dart';
import 'package:legado_reader/core/services/event_bus.dart';
import 'package:legado_reader/core/di/injection.dart';

class BookmarkListPage extends StatefulWidget {
  const BookmarkListPage({super.key});
  @override
  State<BookmarkListPage> createState() => _BookmarkListPageState();
}

class _BookmarkListPageState extends State<BookmarkListPage> {
  final BookmarkDao _bookmarkDao = getIt<BookmarkDao>();
  final BookDao _bookDao = getIt<BookDao>();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _eventSub;
  List<Bookmark> _allBookmarks = [];

  bool _isLoading = true;
  bool _groupByBook = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _eventSub = AppEventBus().onName('up_bookmark').listen((_) => _loadBookmarks(_searchController.text));
  }

  @override
  void dispose() { _searchController.dispose(); _eventSub?.cancel(); super.dispose(); }

  Future<void> _loadBookmarks([String searchKey = '']) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final bookmarks = searchKey.isEmpty ? await _bookmarkDao.getAll() : await _bookmarkDao.search(searchKey);
    final grouped = <String, List<Bookmark>>{};
    for (final bm in bookmarks) { grouped.putIfAbsent(bm.bookName, () => []).add(bm); }
    if (mounted) { setState(() { _allBookmarks = bookmarks; _isLoading = false; }); }
  }

  Future<void> _exportBookmarks({bool asJson = false}) async {
    if (_allBookmarks.isEmpty) return;
    final content = asJson ? jsonEncode(_allBookmarks) : _allBookmarks.map((e) => e.bookText).join('\n');
    await SharePlus.instance.share(ShareParams(text: content, subject: 'Legado 書籤匯出'));
  }

  Future<void> _showExportMenu() async {
    final res = await showModalBottomSheet<int>(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: const Text('文字版'), onTap: () => Navigator.pop(ctx, 0)),
      ListTile(title: const Text('JSON版'), onTap: () => Navigator.pop(ctx, 1)),
    ]));
    if (res != null) _exportBookmarks(asJson: res == 1);
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('清除全部'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('刪除'))]));
    if (confirm == true) { await _bookmarkDao.clearAll(); _loadBookmarks(); }
  }

  Future<void> _editBookmark(Bookmark bookmark) async {
    final ctrl = TextEditingController(text: bookmark.content);
    await showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(bookmark.chapterName), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '筆記')), actions: [
      TextButton(onPressed: () { Navigator.pop(ctx); _jumpToReader(bookmark); }, child: const Text('跳轉')),
      TextButton(onPressed: () async { await _bookmarkDao.upsert(bookmark.copyWith(content: ctrl.text)); if (ctx.mounted) { Navigator.pop(ctx); _loadBookmarks(); } }, child: const Text('保存')),
    ]));
  }

  Future<void> _jumpToReader(Bookmark bookmark) async {
    final book = await _bookDao.getByUrl(bookmark.bookUrl);
    if (book != null && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(book: book, chapterIndex: bookmark.chapterIndex, chapterPos: bookmark.chapterPos)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('書籤筆記'), actions: [
        IconButton(icon: Icon(_groupByBook ? Icons.list : Icons.folder), onPressed: () => setState(() => _groupByBook = !_groupByBook)),
        IconButton(icon: const Icon(Icons.share), onPressed: _allBookmarks.isNotEmpty ? _showExportMenu : null),
        IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _allBookmarks.isNotEmpty ? _clearAll : null),
      ]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: '搜尋...'), onChanged: _loadBookmarks)),
        Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(itemCount: _allBookmarks.length, itemBuilder: (context, i) => ListTile(title: Text(_allBookmarks[i].chapterName), subtitle: Text(_allBookmarks[i].bookText, maxLines: 1), onTap: () => _editBookmark(_allBookmarks[i])))),
      ]),
    );
  }
}



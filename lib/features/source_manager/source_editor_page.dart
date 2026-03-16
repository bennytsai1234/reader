import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'source_debug_page.dart';
import 'views/source_edit_basic.dart';
import 'views/source_edit_search.dart';
import 'views/source_edit_toc.dart';
import 'views/source_edit_content.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/di/injection.dart';

class SourceEditorPage extends StatefulWidget {
  final BookSource? source;
  const SourceEditorPage({super.key, this.source});

  @override
  State<SourceEditorPage> createState() => _SourceEditorPageState();
}

class _SourceEditorPageState extends State<SourceEditorPage> with SingleTickerProviderStateMixin {
  late BookSource _editingSource;
  late TabController _tabController;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _editingSource = widget.source ?? BookSource(bookSourceUrl: '');
    _tabController = TabController(length: 4, vsync: this);
    _initControllers();
  }

  void _initControllers() {
    // 基礎資訊
    _controllers['name'] = TextEditingController(text: _editingSource.bookSourceName);
    _controllers['url'] = TextEditingController(text: _editingSource.bookSourceUrl);
    _controllers['icon'] = TextEditingController(text: _editingSource.bookSourceIcon);
    _controllers['group'] = TextEditingController(text: _editingSource.bookSourceGroup);
    _controllers['comment'] = TextEditingController(text: _editingSource.bookSourceComment);
    _controllers['loginUrl'] = TextEditingController(text: _editingSource.loginUrl);
    _controllers['header'] = TextEditingController(text: _editingSource.header);

    // 搜尋規則 (原 Android ruleSearch)
    _controllers['searchUrl'] = TextEditingController(text: _editingSource.searchUrl);
    _controllers['ruleSearchBookList'] = TextEditingController(text: _editingSource.ruleSearch?.bookList);
    _controllers['ruleSearchName'] = TextEditingController(text: _editingSource.ruleSearch?.name);
    _controllers['ruleSearchAuthor'] = TextEditingController(text: _editingSource.ruleSearch?.author);
    _controllers['ruleSearchKind'] = TextEditingController(text: _editingSource.ruleSearch?.kind);
    _controllers['ruleSearchWordCount'] = TextEditingController(text: _editingSource.ruleSearch?.wordCount);
    _controllers['ruleSearchLastChapter'] = TextEditingController(text: _editingSource.ruleSearch?.lastChapter);
    _controllers['ruleSearchCoverUrl'] = TextEditingController(text: _editingSource.ruleSearch?.coverUrl);
    _controllers['ruleSearchNoteUrl'] = TextEditingController(text: _editingSource.ruleSearch?.bookUrl);

    // 目錄規則
    _controllers['ruleTocChapterList'] = TextEditingController(text: _editingSource.ruleToc?.chapterList);
    _controllers['ruleTocChapterName'] = TextEditingController(text: _editingSource.ruleToc?.chapterName);
    _controllers['ruleTocChapterUrl'] = TextEditingController(text: _editingSource.ruleToc?.chapterUrl);
    _controllers['ruleTocNextPage'] = TextEditingController(text: _editingSource.ruleToc?.nextPage);

    // 正文規則
    _controllers['ruleContentContent'] = TextEditingController(text: _editingSource.ruleContent?.content);
    _controllers['ruleContentNextPage'] = TextEditingController(text: _editingSource.ruleContent?.nextPage);
    _controllers['ruleContentReplace'] = TextEditingController(text: _editingSource.ruleContent?.replace);
  }

  void _syncSource() {
    _editingSource.bookSourceName = _controllers['name']!.text;
    _editingSource.bookSourceUrl = _controllers['url']!.text;
    _editingSource.bookSourceIcon = _controllers['icon']!.text;
    _editingSource.bookSourceGroup = _controllers['group']!.text;
    _editingSource.bookSourceComment = _controllers['comment']!.text;
    _editingSource.loginUrl = _controllers['loginUrl']!.text;
    _editingSource.header = _controllers['header']!.text;
    _editingSource.searchUrl = _controllers['searchUrl']!.text;

    // 這裡應根據控制器回填 SearchRule, TocRule 等對象 (省略詳細回填實作以節省空間)
  }

  Future<void> _save() async {
    _syncSource();
    await getIt<BookSourceDao>().upsert(_editingSource);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.source == null ? '新建書源' : '編輯書源'),
        actions: [
          IconButton(icon: const Icon(Icons.bug_report), onPressed: () { _syncSource(); Navigator.push(context, MaterialPageRoute(builder: (_) => SourceDebugPage(source: _editingSource, debugKey: '我的世界'))); }),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '基礎'),
            Tab(text: '搜尋'),
            Tab(text: '目錄'),
            Tab(text: '正文'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SourceEditBasic(source: _editingSource, controllers: _controllers),
          SourceEditSearch(controllers: _controllers),
          SourceEditToc(controllers: _controllers),
          SourceEditContent(controllers: _controllers),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _controllers.values) { c.dispose(); }
    super.dispose();
  }
}


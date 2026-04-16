import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/engine/analyze_rule.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/shared/widgets/base_scaffold.dart';

/// DebugPage - 規則調試頁面
/// (原 Android ui/book/source/debug/DebugActivity.kt)
class DebugPage extends StatefulWidget {
  final BookSource source;
  const DebugPage({super.key, required this.source});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _logSub;
  bool _isDebugging = false;

  @override
  void initState() {
    super.initState();
    _initLogs();
    _searchController.text = widget.source.ruleSearch?.checkKeyWord ?? '我的';
  }

  void _initLogs() {
    AnalyzeRuleBase.debugLogController ??= StreamController<String>.broadcast();
    _logSub = AnalyzeRuleBase.debugLogController!.stream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
        });
        _scrollToBottom();
      }
    });
  }

  void _startDebug(String key) async {
    if (_isDebugging) return;
    setState(() {
      _isDebugging = true;
      _logs.clear();
      _logs.add('⇒ 開始偵錯: $key');
    });

    final service = BookSourceService();
    final source = widget.source;
    AnalyzeRuleBase.debugLogController ??= StreamController<String>.broadcast();

    try {
      if (key.startsWith('http')) {
        // 1. 詳情頁偵錯
        _logs.add('︾ 開始解析詳情頁');
        var book = Book(bookUrl: key, name: '偵錯書籍', author: '', origin: source.bookSourceUrl, originName: source.bookSourceName, isInBookshelf: false);
        book = await service.getBookInfo(source, book);
        _logs.add('✓ 詳情頁解析完成: ${book.name}');
        
        // 2. 目錄頁偵錯
        _logs.add('︾ 開始解析目錄頁');
        final chapters = await service.getChapterList(source, book);
        _logs.add('✓ 目錄頁解析完成，共 ${chapters.length} 章');
        
        if (chapters.isNotEmpty) {
          // 3. 正文偵錯 (第一章)
          _logs.add('︾ 開始解析正文頁: ${chapters.first.title}');
          final content = await service.getContent(source, book, chapters.first);
          _logs.add('✓ 正文解析完成，長度: ${content.length}');
          _logs.add('︽ 偵錯結束');
        }
      } else {
        // 搜尋偵錯
        _logs.add('︾ 開始解析搜尋頁');
        final searchResults = await service.searchBooks(source, key);
        if (searchResults.isNotEmpty) {
          final first = searchResults.first;
          _logs.add('✓ 搜尋頁解析成功: ${first.name}');
          
          // 繼續詳情頁
          _logs.add('︾ 開始解析詳情頁');
          var book = first.toBook();
          book = await service.getBookInfo(source, book);
          _logs.add('✓ 詳情頁解析完成: ${book.name}');
          
          // 目錄頁
          _logs.add('︾ 開始解析目錄頁');
          final chapters = await service.getChapterList(source, book);
          _logs.add('✓ 目錄頁解析完成，共 ${chapters.length} 章');
          
          if (chapters.isNotEmpty) {
            _logs.add('︾ 開始解析正文頁: ${chapters.first.title}');
            final content = await service.getContent(source, book, chapters.first);
            _logs.add('✓ 正文解析完成，長度: ${content.length}');
          }
          _logs.add('︽ 偵錯結束');
        } else {
          _logs.add('✕ 搜尋結果為空');
        }
      }
    } catch (e) {
      _logs.add('✕ 偵錯出錯: $e');
    } finally {
      if (mounted) {
        setState(() => _isDebugging = false);
        _logs.add('1000'); // 模擬 Android state = 1000 (結束)
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '調試: ${widget.source.bookSourceName}',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: '清空日誌',
          onPressed: () => setState(() => _logs.clear()),
        ),
      ],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜尋關鍵字或 URL',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _startDebug,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isDebugging ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
                  onPressed: () => _startDebug(_searchController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[50],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: SelectableText(
                      log,
                      style: TextStyle(
                        fontFamily: 'Courier', // 模擬終端字體
                        fontSize: 13,
                        fontWeight: log.startsWith('⇒') ? FontWeight.bold : FontWeight.normal,
                        color: _getLogColor(context, log),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(BuildContext context, String log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (log.startsWith('⇒')) return isDark ? Colors.lightBlueAccent : Colors.blue[800]!;
    if (log.contains('✕') || log.contains('Error') || log.contains('失敗')) return Colors.red;
    if (log.contains('✓') || log.contains('成功')) return Colors.green;
    if (log.startsWith('  ◇')) return isDark ? Colors.orangeAccent : Colors.orange[800]!;
    if (log.startsWith('  └')) return isDark ? Colors.white70 : Colors.black54;
    return isDark ? Colors.white : Colors.black87;
  }
}


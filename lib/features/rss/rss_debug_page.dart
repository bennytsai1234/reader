import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/services/rss_parser.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';

class RssDebugPage extends StatefulWidget {
  final RssSource source;
  const RssDebugPage({super.key, required this.source});

  @override
  State<RssDebugPage> createState() => _RssDebugPageState();
}

class _RssDebugPageState extends State<RssDebugPage> {
  final List<String> _logs = [];
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _startDebug();
  }

  void _log(String msg) {
    if (mounted) {
      setState(() {
        _logs.add('[${DateTime.now().toString().substring(11, 19)}] $msg');
      });
    }
  }

  Future<void> _startDebug() async {
    _log('⇒ 開始調試 RSS 源: ${widget.source.sourceName}');
    try {
      _log('︾ 正在請求列表: ${widget.source.sourceUrl}');
      final analyzeUrl = AnalyzeUrl(widget.source.sourceUrl);
      final body = await analyzeUrl.getResponseBody();
      _log('︽ 請求成功，長度: ${body.length}');

      _log('︾ 正在解析列表...');
      final articles = await RssParser.parseArticles(widget.source, body, widget.source.sourceUrl);
      _log('︽ 解析完成，獲取到 ${articles.length} 篇文章');

      if (articles.isNotEmpty) {
        final first = articles.first;
        _log('📄 第一篇文章: ${first.title}');
        _log('🔗 連結: ${first.link}');

        if (widget.source.ruleContent != null && widget.source.ruleContent!.isNotEmpty) {
          _log('︾ 正在測試正文規則: ${first.link}');
          final artAnalyzeUrl = AnalyzeUrl(first.link);
          final artBody = await artAnalyzeUrl.getResponseBody();
          final content = await RssParser.parseContent(widget.source, artBody, first.link);
          _log('︽ 正文解析成功，長度: ${content.length}');
          _log('📝 內容預覽: ${content.length > 100 ? content.substring(0, 100) : content}...');
        } else {
          _log('≡ 未配置正文規則，將使用 WebView 渲染');
        }
      }
      _log('✅ 調試完成');
    } catch (e) {
      _log('❌ 發生錯誤: $e');
    } finally {
      if (mounted) setState(() => _isFinished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSS 調試'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isFinished ? () {
              setState(() => _logs.clear());
              _startDebug();
            } : null,
          )
        ],
      ),
      body: Container(
        color: Colors.black,
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          itemCount: _logs.length,
          itemBuilder: (context, index) => Text(
            _logs[index],
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
    );
  }
}


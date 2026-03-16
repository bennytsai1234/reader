import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';
import 'dict_provider.dart';

class DictDialog extends StatefulWidget {
  final String word;
  const DictDialog({super.key, required this.word});

  @override
  State<DictDialog> createState() => _DictDialogState();

  static void show(BuildContext context, String word) {
    showDialog(
      context: context,
      builder: (context) => DictDialog(word: word),
    );
  }
}

class _DictDialogState extends State<DictDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DictProvider>().loadRules().then((_) {
        if (!mounted) return;
        final provider = context.read<DictProvider>();
        if (provider.rules.isNotEmpty) {
          provider.search(widget.word, rule: provider.rules.first);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DictProvider>(
      builder: (context, provider, child) {
        final rules = provider.rules;
        
        if (rules.isEmpty) {
          return AlertDialog(
            title: Text('查詞: ${widget.word}'),
            content: const Text('請先在設定中啟用至少一個字典規則'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('關閉'),
              ),
            ],
          );
        }

        return DefaultTabController(
          length: rules.length,
          child: AlertDialog(
            titlePadding: EdgeInsets.zero,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '查詞: ${widget.word}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  isScrollable: rules.length > 3,
                  onTap: (index) {
                    provider.search(widget.word, rule: rules[index]);
                  },
                  tabs: rules.map((r) => Tab(text: r.name)).toList(),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: HtmlWidget(
                        provider.result.isEmpty ? '正在查詢...' : provider.result,
                        textStyle: const TextStyle(fontSize: 14),
                        // 處理 HTML 點擊跳轉 (如果需要)
                        onTapUrl: (url) {
                          debugPrint('HTML Tap: $url');
                          return true;
                        },
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}


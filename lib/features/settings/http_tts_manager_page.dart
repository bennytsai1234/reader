import 'package:legado_reader/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/database/dao/http_tts_dao.dart';
import 'package:legado_reader/core/models/http_tts.dart';

class HttpTtsManagerPage extends StatefulWidget {
  const HttpTtsManagerPage({super.key});

  @override
  State<HttpTtsManagerPage> createState() => _HttpTtsManagerPageState();
}

class _HttpTtsManagerPageState extends State<HttpTtsManagerPage> {
  final HttpTtsDao _dao = getIt<HttpTtsDao>();
  List<HttpTTS> _engines = [];

  @override
  void initState() {
    super.initState();
    _loadEngines();
  }

  Future<void> _loadEngines() async {
    final list = await _dao.getAll();
    setState(() {
      _engines = list;
    });
  }

  void _addEngine({HttpTTS? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? '新增 HTTP TTS 引擎' : '編輯 HTTP TTS 引擎'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '引擎名稱'),
            ),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL (包含 {{speakText}})'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                final engine = HttpTTS(
                  id: existing?.id ?? 0, // Auto-increment if 0
                  name: nameController.text,
                  url: urlController.text,
                );
                await _dao.upsert(engine);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadEngines();
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _deleteEngine(HttpTTS engine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除確認'),
        content: Text('確定要刪除引擎 "${engine.name}" 嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dao.deleteById(engine.id);
      _loadEngines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP TTS 引擎管理'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _addEngine()),
        ],
      ),
      body: _engines.isEmpty
          ? const Center(child: Text('尚未新增任何引擎'))
          : ListView.builder(
              itemCount: _engines.length,
              itemBuilder: (context, index) {
                final engine = _engines[index];
                return ListTile(
                  title: Text(engine.name),
                  subtitle: Text(engine.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addEngine(existing: engine),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEngine(engine),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}


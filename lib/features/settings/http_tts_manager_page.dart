import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/core/models/http_tts.dart';
import 'http_tts_provider.dart';

class HttpTtsManagerPage extends StatelessWidget {
  const HttpTtsManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HttpTtsProvider(),
      child: const _HttpTtsManagerView(),
    );
  }
}

class _HttpTtsManagerView extends StatelessWidget {
  const _HttpTtsManagerView();

  void _showEditDialog(BuildContext context, {HttpTTS? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '新增 HTTP TTS 引擎' : '編輯 HTTP TTS 引擎'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '引擎名稱')),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'URL (包含 {{speakText}})'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                final engine = HttpTTS(
                  id: existing?.id ?? 0,
                  name: nameController.text,
                  url: urlController.text,
                );
                if (!ctx.mounted) return;
                await context.read<HttpTtsProvider>().upsert(engine);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, HttpTTS engine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除確認'),
        content: Text('確定要刪除引擎 "${engine.name}" 嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('刪除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<HttpTtsProvider>().delete(engine.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HttpTtsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP TTS 引擎管理'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showEditDialog(context))],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.engines.isEmpty
              ? const Center(child: Text('尚未新增任何引擎'))
              : ListView.builder(
                  itemCount: provider.engines.length,
                  itemBuilder: (context, index) {
                    final engine = provider.engines[index];
                    return ListTile(
                      title: Text(engine.name),
                      subtitle: Text(engine.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(context, existing: engine)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(context, engine)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

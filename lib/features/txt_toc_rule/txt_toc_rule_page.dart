import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'txt_toc_rule_provider.dart';
import 'package:inkpage_reader/core/models/txt_toc_rule.dart';

class TxtTocRulePage extends StatelessWidget {
  const TxtTocRulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TxtTocRuleProvider(),
      child: Consumer<TxtTocRuleProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('本地TXT目錄規則'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showEditDialog(context, provider, null),
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.rules.isEmpty
                    ? const Center(child: Text('暫無規則'))
                    : ListView.separated(
                        itemCount: provider.rules.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) => _buildRuleItem(context, provider, provider.rules[i]),
                      ),
          );
        },
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, TxtTocRuleProvider p, TxtTocRule rule) {
    return ListTile(
      title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(rule.rule, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: rule.enable,
            onChanged: (val) => p.toggleEnable(rule),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => _showEditDialog(context, p, rule),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => p.deleteRule(rule),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, TxtTocRuleProvider p, TxtTocRule? rule) {
    final nameCtrl = TextEditingController(text: rule?.name ?? '');
    final ruleCtrl = TextEditingController(text: rule?.rule ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rule == null ? '新增規則' : '編輯規則'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名稱')),
              TextField(controller: ruleCtrl, decoration: const InputDecoration(labelText: '正則表達式'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final newRule = TxtTocRule(
                id: rule?.id ?? DateTime.now().millisecondsSinceEpoch,
                name: nameCtrl.text,
                rule: ruleCtrl.text,
                enable: rule?.enable ?? true,
              );
              p.saveRule(newRule);
              Navigator.pop(ctx);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}


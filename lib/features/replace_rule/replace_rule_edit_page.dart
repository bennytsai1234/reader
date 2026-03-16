import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import 'widgets/replace_edit_form.dart';
import 'widgets/replace_edit_options.dart';
import 'widgets/replace_edit_test_panel.dart';

class ReplaceRuleEditPage extends StatefulWidget {
  final ReplaceRule? rule;
  final Function(ReplaceRule) onSave;

  const ReplaceRuleEditPage({super.key, this.rule, required this.onSave});

  @override
  State<ReplaceRuleEditPage> createState() => _ReplaceRuleEditPageState();
}

class _ReplaceRuleEditPageState extends State<ReplaceRuleEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _groupCtrl, _patternCtrl, _replacementCtrl, _scopeCtrl, _excludeScopeCtrl, _timeoutCtrl;
  final TextEditingController _testInputCtrl = TextEditingController(text: '這是一段測試文字，包含 junk123 內容。');
  String _testResult = '';
  bool _isEnabled = true, _isRegex = true, _scopeTitle = false, _scopeContent = true;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _groupCtrl = TextEditingController(text: r?.group ?? '');
    _patternCtrl = TextEditingController(text: r?.pattern ?? '');
    _replacementCtrl = TextEditingController(text: r?.replacement ?? '');
    _scopeCtrl = TextEditingController(text: r?.scope ?? '');
    _excludeScopeCtrl = TextEditingController(text: r?.excludeScope ?? '');
    _timeoutCtrl = TextEditingController(text: (r?.timeoutMillisecond ?? 3000).toString());
    _isEnabled = r?.isEnabled ?? true;
    _isRegex = r?.isRegex ?? true;
    _scopeTitle = r?.scopeTitle ?? false;
    _scopeContent = r?.scopeContent ?? true;
    for (final c in [_patternCtrl, _replacementCtrl, _testInputCtrl]) {
      c.addListener(_runTest);
    }
    _runTest();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _groupCtrl, _patternCtrl, _replacementCtrl, _scopeCtrl, _excludeScopeCtrl, _timeoutCtrl, _testInputCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _runTest() {
    final r = ReplaceRule(pattern: _patternCtrl.text, replacement: _replacementCtrl.text, isRegex: _isRegex);
    setState(() {
      _testResult = r.apply(_testInputCtrl.text);
    });
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final r = ReplaceRule(id: widget.rule?.id ?? 0, name: _nameCtrl.text.trim(), group: _groupCtrl.text.trim(), pattern: _patternCtrl.text.trim(), replacement: _replacementCtrl.text, scope: _scopeCtrl.text.trim(), excludeScope: _excludeScopeCtrl.text.trim(), timeoutMillisecond: int.tryParse(_timeoutCtrl.text) ?? 3000, isEnabled: _isEnabled, isRegex: _isRegex, scopeTitle: _scopeTitle, scopeContent: _scopeContent, order: widget.rule?.order ?? 0);
      if (!r.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正則表達式語法錯誤，請檢查！')));
        return;
      }
      widget.onSave(r);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.rule == null ? '新增替換規則' : '編輯替換規則'), actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save, tooltip: '儲存')]),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16.0), children: [
        ReplaceEditForm(nameCtrl: _nameCtrl, groupCtrl: _groupCtrl, timeoutCtrl: _timeoutCtrl, patternCtrl: _patternCtrl, replacementCtrl: _replacementCtrl),
        const SizedBox(height: 16),
        ExpansionTile(title: const Text('進階範圍設定', style: TextStyle(fontSize: 14)), children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: TextFormField(controller: _scopeCtrl, decoration: const InputDecoration(labelText: '作用範圍 (書名/書源URL)', border: OutlineInputBorder()))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: TextFormField(controller: _excludeScopeCtrl, decoration: const InputDecoration(labelText: '排除範圍 (書名/書源URL)', border: OutlineInputBorder()))),
        ]),
        const Divider(height: 32),
        ReplaceEditOptions(isEnabled: _isEnabled, isRegex: _isRegex, scopeTitle: _scopeTitle, scopeContent: _scopeContent, onEnabledChanged: (v) => setState(() => _isEnabled = v), onRegexChanged: (v) { setState(() => _isRegex = v); _runTest(); }, onTitleChanged: (v) => setState(() => _scopeTitle = v), onContentChanged: (v) => setState(() => _scopeContent = v)),
        const SizedBox(height: 24),
        ReplaceEditTestPanel(testInputCtrl: _testInputCtrl, testResult: _testResult),
        const SizedBox(height: 40),
      ])),
    );
  }
}


import 'package:legado_reader/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/database/dao/rss_source_dao.dart';
import 'rss_debug_page.dart';

class RssSourceEditorPage extends StatefulWidget {
  final RssSource? source;
  const RssSourceEditorPage({super.key, this.source});

  @override
  State<RssSourceEditorPage> createState() => _RssSourceEditorPageState();
}

class _RssSourceEditorPageState extends State<RssSourceEditorPage> {
  late RssSource _editingSource;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _iconController;
  late TextEditingController _groupController;
  late TextEditingController _articlesRuleController;
  late TextEditingController _titleRuleController;
  late TextEditingController _linkRuleController;
  late TextEditingController _pubDateRuleController;
  late TextEditingController _descRuleController;
  late TextEditingController _imageRuleController;
  late TextEditingController _contentRuleController;

  @override
  void initState() {
    super.initState();
    _editingSource = widget.source ?? RssSource(sourceUrl: '');
    _nameController = TextEditingController(text: _editingSource.sourceName);
    _urlController = TextEditingController(text: _editingSource.sourceUrl);
    _iconController = TextEditingController(text: _editingSource.sourceIcon);
    _groupController = TextEditingController(text: _editingSource.sourceGroup);
    _articlesRuleController = TextEditingController(text: _editingSource.ruleArticles);
    _titleRuleController = TextEditingController(text: _editingSource.ruleTitle);
    _linkRuleController = TextEditingController(text: _editingSource.ruleLink);
    _pubDateRuleController = TextEditingController(text: _editingSource.rulePubDate);
    _descRuleController = TextEditingController(text: _editingSource.ruleDescription);
    _imageRuleController = TextEditingController(text: _editingSource.ruleImage);
    _contentRuleController = TextEditingController(text: _editingSource.ruleContent);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _iconController.dispose();
    _groupController.dispose();
    _articlesRuleController.dispose();
    _titleRuleController.dispose();
    _linkRuleController.dispose();
    _pubDateRuleController.dispose();
    _descRuleController.dispose();
    _imageRuleController.dispose();
    _contentRuleController.dispose();
    super.dispose();
  }

  void _syncSource() {
    _editingSource.sourceName = _nameController.text;
    _editingSource.sourceUrl = _urlController.text;
    _editingSource.sourceIcon = _iconController.text;
    _editingSource.sourceGroup = _groupController.text;
    _editingSource.ruleArticles = _articlesRuleController.text;
    _editingSource.ruleTitle = _titleRuleController.text;
    _editingSource.ruleLink = _linkRuleController.text;
    _editingSource.rulePubDate = _pubDateRuleController.text;
    _editingSource.ruleDescription = _descRuleController.text;
    _editingSource.ruleImage = _imageRuleController.text;
    _editingSource.ruleContent = _contentRuleController.text;
  }

  Future<void> _save() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL 不能為空')));
      return;
    }

    _syncSource();
    await getIt<RssSourceDao>().upsert(_editingSource);
    if (mounted) Navigator.pop(context);
  }

  void _showDebug() {
    _syncSource();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RssDebugPage(source: _editingSource)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.source == null ? '新建 RSS 來源' : '編輯 RSS 來源'),
        actions: [
          IconButton(icon: const Icon(Icons.bug_report), onPressed: _showDebug),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSection('基本資訊', [
                _buildTextField('名稱', _nameController),
                _buildTextField('URL', _urlController),
                _buildTextField('圖標 URL', _iconController),
                _buildTextField('分組', _groupController),
              ]),
              _buildSection('自訂解析規則 (留空則使用預設 XML 解析)', [
                _buildTextField('列表規則 (ruleArticles)', _articlesRuleController),
                _buildTextField('標題規則', _titleRuleController),
                _buildTextField('鏈接規則', _linkRuleController),
                _buildTextField('日期規則', _pubDateRuleController),
                _buildTextField('描述規則', _descRuleController),
                _buildTextField('圖片規則', _imageRuleController),
                _buildTextField('正文規則', _contentRuleController),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}


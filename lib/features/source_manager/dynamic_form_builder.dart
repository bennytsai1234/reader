import 'dart:convert';
import 'package:flutter/material.dart';

/// DynamicFormBuilder - 動態表單生成器
/// 根據書源的 loginUi (JSON) 動態渲染 Flutter 組件
class DynamicFormBuilder extends StatelessWidget {
  final String loginUiJson;
  final Map<String, TextEditingController> controllers;
  final Function(String action, Map<String, String> data) onAction;

  const DynamicFormBuilder({
    super.key,
    required this.loginUiJson,
    required this.controllers,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final decoded = jsonDecode(loginUiJson);
      final rows = decoded is List ? decoded : [decoded];
      
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 16,
              children: rows.map((row) => _buildItem(context, row as Map<String, dynamic>)).toList(),
            ),
          ],
        ),
      );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('LoginUI 解析失敗:\n$e', 
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildItem(BuildContext context, Map<String, dynamic> row) {
    final name = row['name']?.toString() ?? '';
    final type = row['type']?.toString() ?? 'text';
    final action = row['action']?.toString();
    final style = row['style'] as Map<String, dynamic>?;

    // 處理彈性佈局寬度
    double? width;
    if (style != null && style.containsKey('layout_flexGrow')) {
      // 簡單模擬 flexGrow
      if (style['layout_flexGrow'] > 0) width = double.infinity;
    }

    if (type == 'button') {
      return SizedBox(
        width: width,
        child: ElevatedButton(
          onPressed: () {
            final data = controllers.map((k, v) => MapEntry(k, v.text));
            onAction(action ?? name, data);
          },
          child: Text(name),
        ),
      );
    }

    // 初始化控制器
    if (!controllers.containsKey(name)) {
      controllers[name] = TextEditingController();
    }

    return SizedBox(
      width: width ?? (MediaQuery.of(context).size.width > 600 ? 300 : double.infinity),
      child: TextField(
        controller: controllers[name],
        obscureText: type == 'password',
        decoration: InputDecoration(
          labelText: name,
          hintText: '請輸入 $name',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}


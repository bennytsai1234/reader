import 'package:flutter/material.dart';

class ReplaceEditTestPanel extends StatelessWidget {
  final TextEditingController testInputCtrl;
  final String testResult;

  const ReplaceEditTestPanel({
    super.key,
    required this.testInputCtrl,
    required this.testResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('規則調試', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: testInputCtrl,
            decoration: const InputDecoration(
              labelText: '測試文字',
              hintText: '請輸入要測試的內容',
              isDense: true,
            ),
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text('替換結果:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              testResult.isEmpty ? '(無結果)' : testResult,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}


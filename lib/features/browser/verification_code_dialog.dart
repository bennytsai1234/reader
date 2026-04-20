import 'package:flutter/material.dart';

import 'package:inkpage_reader/core/services/source_verification_service.dart';

class VerificationCodeDialog extends StatefulWidget {
  final VerificationRequest request;

  const VerificationCodeDialog({super.key, required this.request});

  @override
  State<VerificationCodeDialog> createState() => _VerificationCodeDialogState();
}

class _VerificationCodeDialogState extends State<VerificationCodeDialog> {
  late final TextEditingController _controller = TextEditingController();

  void _submit() {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先輸入驗證碼')));
      return;
    }
    SourceVerificationService().sendResult(widget.request, code);
    Navigator.of(context).pop();
  }

  void _cancel() {
    SourceVerificationService().cancelRequest(widget.request);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _cancel();
        }
      },
      child: AlertDialog(
        title: Text(widget.request.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.request.url,
                fit: BoxFit.contain,
                height: 120,
                errorBuilder:
                    (_, __, ___) => const SizedBox(
                      height: 120,
                      child: Center(child: Text('驗證圖片載入失敗')),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '驗證碼',
                hintText: '請輸入畫面上的驗證碼',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: _cancel, child: const Text('取消')),
          FilledButton(onPressed: _submit, child: const Text('送出')),
        ],
      ),
    );
  }
}

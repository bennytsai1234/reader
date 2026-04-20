import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:inkpage_reader/core/services/source_verification_service.dart';

import 'browser_params.dart';
import 'browser_provider.dart';

class BrowserPage extends StatefulWidget {
  final BrowserParams params;

  const BrowserPage({super.key, required this.params});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  late final BrowserProvider _provider = BrowserProvider(widget.params);
  WebViewController? _webViewController;
  bool _isBootstrapping = true;
  bool _isSubmitting = false;
  String? _currentUrl;

  VerificationRequest? get _request => widget.params.verificationRequest;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _provider.init();
    if (!mounted) {
      return;
    }

    if (!_provider.isInitialized) {
      setState(() {
        _isBootstrapping = false;
      });
      return;
    }

    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) {
                _currentUrl = url;
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          );

    final initialUrl = _provider.baseUrl ?? widget.params.url;
    _currentUrl = initialUrl;

    if ((_provider.html ?? '').isNotEmpty) {
      await controller.loadHtmlString(_provider.html!, baseUrl: initialUrl);
    } else {
      await controller.loadRequest(
        Uri.parse(initialUrl),
        headers: _provider.headerMap,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _webViewController = controller;
      _isBootstrapping = false;
    });
  }

  Future<void> _confirm() async {
    final request = _request;
    final controller = _webViewController;
    if (request == null || controller == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentHtml = await _readHtml(controller);
      final currentCookie = await _readCookie(controller);
      final currentUrl = await controller.currentUrl() ?? _currentUrl;
      final result = await _provider.saveVerificationResult(
        currentHtml,
        currentUrl: currentUrl,
        cookie: currentCookie,
      );

      if (!mounted) {
        return;
      }

      SourceVerificationService().sendResult(request, result ?? currentHtml);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('驗證結果保存失敗: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<String> _readHtml(WebViewController controller) async {
    final raw = await controller.runJavaScriptReturningResult(
      'document.documentElement.outerHTML',
    );
    return _normalizeJavascriptResult(raw);
  }

  Future<String> _readCookie(WebViewController controller) async {
    final raw = await controller.runJavaScriptReturningResult(
      'document.cookie',
    );
    return _normalizeJavascriptResult(raw);
  }

  String _normalizeJavascriptResult(Object raw) {
    final value = raw.toString();
    if (value == 'null' || value.isEmpty) {
      return '';
    }
    try {
      final decoded = jsonDecode(value);
      return decoded?.toString() ?? '';
    } catch (_) {
      return value;
    }
  }

  void _cancel([String message = '驗證已取消']) {
    final request = _request;
    if (request != null && SourceVerificationService().isPending(request)) {
      SourceVerificationService().cancelRequest(request, message);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _provider.dispose();
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.params.title),
          actions: [
            TextButton(
              onPressed: _isSubmitting ? null : _confirm,
              child: const Text('完成驗證'),
            ),
          ],
        ),
        body:
            _isBootstrapping
                ? const Center(child: CircularProgressIndicator())
                : _provider.errorMessage != null
                ? _buildErrorState(context)
                : Stack(
                  children: [
                    if (_webViewController != null)
                      WebViewWidget(controller: _webViewController!),
                    if (_isSubmitting)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _cancel,
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _confirm,
                    child: const Text('完成驗證'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 16),
          Text(
            _provider.errorMessage ?? '驗證頁面載入失敗',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _cancel('驗證頁面載入失敗'),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}

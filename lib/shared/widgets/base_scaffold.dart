import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// BaseScaffold - 全域頁面封裝
/// (原 Android BaseActivity) 封裝，支援統一的 Loading 顯示、錯誤處理與系統欄適配
class BaseScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;
  final bool isLoading;
  final String? error;
  final bool centeredTitle;
  final VoidCallback? onRetry;

  const BaseScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.title,
    this.actions,
    this.showAppBar = true,
    this.isLoading = false,
    this.error,
    this.centeredTitle = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // 模擬 Android setupSystemBar 的自動顏色適配
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        appBar: showAppBar
            ? (appBar ??
                AppBar(
                  title: title != null ? Text(title!) : null,
                  actions: actions,
                  centerTitle: centeredTitle,
                ))
            : null,
        body: Stack(
          children: [
            body,
            if (error != null && error!.isNotEmpty)
              _buildErrorView(context),
            if (isLoading)
              _buildLoadingView(),
          ],
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('載入中...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重試'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


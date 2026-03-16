import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:legado_reader/features/settings/settings_provider.dart';
import 'package:legado_reader/core/services/default_data.dart';
import 'main_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _status = '正在初始化...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      setState(() => _status = '正在載入資料庫與預設資料...');
      await DefaultData.init();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    } catch (e, stack) {
      debugPrint('Init Error: $e\n$stack');
      if (mounted) {
        setState(() { _error = '$e\n$stack'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final customPath = isDarkMode ? settings.welcomeImageDark : settings.welcomeImage;
    final showIcon = isDarkMode ? settings.welcomeShowIconDark : settings.welcomeShowIcon;
    final showText = isDarkMode ? settings.welcomeShowTextDark : settings.welcomeShowText;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          customPath.isNotEmpty && File(customPath).existsSync()
              ? Image.file(File(customPath), fit: BoxFit.cover)
              : Image.asset(
                  'assets/welcome_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: const Center(
                      child: Icon(Icons.library_books, size: 100, color: Colors.blue),
                    ),
                  ),
                ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
              ),
            ),
          ),
          Positioned(
            bottom: 80, left: 0, right: 0,
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('啟動失敗: $_error', style: const TextStyle(color: Colors.redAccent)),
                  )
                : Column(
                    children: [
                      if (showIcon) ...[
                        const Icon(Icons.library_books, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                      ],
                      if (showText) ...[
                        const Text(
                          'Legado Reader',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '「 讀萬卷書，行萬里路 」',
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 40),
                      Text(_status, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.white10),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}


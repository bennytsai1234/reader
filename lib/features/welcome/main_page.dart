import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_page.dart';
import 'package:legado_reader/features/explore/explore_page.dart';
import 'package:legado_reader/features/settings/settings_page.dart';
import 'package:legado_reader/features/rss/rss_source_page.dart';
import 'package:legado_reader/features/bookshelf/bookshelf_provider.dart';
import 'package:legado_reader/features/settings/settings_provider.dart';
import 'package:legado_reader/core/services/webdav_service.dart';
import 'package:legado_reader/core/services/source_verification_service.dart';
import 'package:legado_reader/features/association/association_handler_service.dart';
import 'package:legado_reader/features/browser/browser_page.dart';
import 'package:legado_reader/features/browser/browser_params.dart';
import 'package:legado_reader/core/engine/app_event_bus.dart';
import 'package:legado_reader/core/services/app_log_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime _lastTapTime = DateTime.now();
  DateTime? _lastBackTime;
  StreamSubscription? _verificationSubscription;
  StreamSubscription? _logToastSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AssociationHandlerService().init(context);
      _initVerificationListener();
      _checkLocalPassword();
      _checkBackupSync();
      _checkVersionUpdate();
      _autoRefreshBookshelf();
      _initLogToastListener();
    });
  }

  @override
  void dispose() {
    _verificationSubscription?.cancel();
    _logToastSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initVerificationListener() {
    _verificationSubscription = SourceVerificationService().requestStream.listen((request) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => BrowserPage(params: BrowserParams(url: request.url, title: request.title, sourceOrigin: request.sourceKey, sourceVerificationEnable: true, verificationRequest: request))));
    });
  }

  void _initLogToastListener() {
    _logToastSubscription = AppLog.toastStream.listen((message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
    });
  }

  Future<void> _checkVersionUpdate() async {
    final settings = context.read<SettingsProvider>();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;
    if (currentVersion != settings.lastVersionCode && mounted) {
      final isFirst = settings.lastVersionCode == 0;
      settings.setLastVersionCode(currentVersion);
      if (!mounted) return;
      showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(isFirst ? '歡迎使用' : '更新日誌'), content: Text(isFirst ? '感謝您使用 Legado Reader！' : '版本已更新至 v${packageInfo.version}'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('確定'))]));
    }
  }

  void _checkLocalPassword() {
    final settings = context.read<SettingsProvider>();
    if (settings.localPassword.isNotEmpty) {
      final ctrl = TextEditingController();
      showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(title: const Text('身份驗證'), content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '輸入密碼'), obscureText: true), actions: [ElevatedButton(onPressed: () { if (ctrl.text.trim() == settings.localPassword) Navigator.pop(ctx); }, child: const Text('確定'))]));
    }
  }

  Future<void> _checkBackupSync() async {
    final settings = context.read<SettingsProvider>();
    
    // 1. 檢查是否有新備份需要還原 (Android parity)
    final remote = await settings.checkWebDavBackupSync();
    if (remote != null && mounted) {
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: const Text('發現新備份'), 
          content: Text('是否從 WebDav 還原：$remote？'), 
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), 
            ElevatedButton(
              onPressed: () async { 
                Navigator.pop(ctx); 
                await WebDavService().restoreLatestBackup(); 
                if (mounted) context.read<BookshelfProvider>().loadBooks(); 
              }, 
              child: const Text('還原')
            )
          ]
        )
      );
    }

    // 2. 檢查是否需要自動備份 (Android parity: 24h interval)
    if (settings.autoBackup && settings.webdavEnabled) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - settings.lastBackup > 24 * 60 * 60 * 1000) {
        AppLog.i('觸發 24 小時背景自動備份...');
        WebDavService().uploadFullBackup().then((success) {
          if (success) {
            settings.setLastBackup(now);
            AppLog.i('背景自動備份成功');
          }
        });
      }
    }
  }

  Future<void> _autoRefreshBookshelf() async {
    final provider = context.read<BookshelfProvider>();
    await provider.refreshBookshelf();
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) { setState(() => _currentIndex = 0); return false; }
    final now = DateTime.now();
    if (_lastBackTime == null || now.difference(_lastBackTime!) > const Duration(seconds: 2)) {
      _lastBackTime = now;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('再按一次退出'), duration: Duration(seconds: 2)));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(builder: (context, settings, child) {
      final items = <Map<String, dynamic>>[{'icon': Icons.book_outlined, 'selectedIcon': Icons.book, 'label': '書架', 'page': const BookshelfPage()}];
      if (settings.showDiscovery) items.add({'icon': Icons.explore_outlined, 'selectedIcon': Icons.explore, 'label': '發現', 'page': const ExplorePage()});
      if (settings.showRss) items.add({'icon': const Icon(Icons.rss_feed), 'label': '訂閱', 'page': const RssSourcePage()});
      items.add({'icon': Icons.person_outline, 'selectedIcon': Icons.person, 'label': '我的', 'page': const SettingsPage()});

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (await _onWillPop() && mounted) await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        },
        child: Scaffold(
          body: IndexedStack(index: _currentIndex, children: items.map((i) => i['page'] as Widget).toList()),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              if (_currentIndex == index) {
                if (DateTime.now().difference(_lastTapTime).inMilliseconds < 300) {
                  final label = items[index]['label'];
                  if (label == '書架') AppEventBus().fire(AppEventBus.upBookshelf);
                }
                _lastTapTime = DateTime.now();
                return;
              }
              setState(() => _currentIndex = index);
            },
            destinations: items.map((i) => NavigationDestination(icon: i['icon'] is Widget ? i['icon'] : Icon(i['icon'] as IconData), label: i['label'])).toList(),
          ),
        ),
      );
    });
  }
}


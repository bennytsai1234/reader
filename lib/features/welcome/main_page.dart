import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/default_data.dart';
import 'package:inkpage_reader/features/bookshelf/bookshelf_page.dart';
import 'package:inkpage_reader/features/explore/explore_page.dart';
import 'package:inkpage_reader/features/settings/settings_page.dart';
import 'package:inkpage_reader/features/bookshelf/bookshelf_provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  DateTime _lastTapTime = DateTime.now();
  DateTime? _lastBackPressedAt;

  static const _exitBackInterval = Duration(seconds: 2);
  static const _destinations = <_MainDestination>[
    _MainDestination(
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
      label: '書架',
      page: BookshelfPage(),
    ),
    _MainDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: '發現',
      page: ExplorePage(),
    ),
    _MainDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: '我的',
      page: SettingsPage(),
    ),
  ];
  final List<Widget?> _pages = List<Widget?>.filled(_destinations.length, null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initDeferredStartupData());
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackIntent();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            _destinations.length,
            (index) =>
                _pages[index] != null || index == _currentIndex
                    ? _pageAt(index)
                    : const SizedBox.shrink(),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (_currentIndex == index) {
              if (DateTime.now().difference(_lastTapTime).inMilliseconds <
                  300) {
                final label = _destinations[index].label;
                if (label == '書架') {
                  context.read<BookshelfProvider>().loadBooks();
                }
              }
              _lastTapTime = DateTime.now();
            }
            setState(() => _currentIndex = index);
          },
          destinations:
              _destinations
                  .map(
                    (destination) => NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _pageAt(int index) {
    return _pages[index] ??= _destinations[index].page;
  }

  Future<void> _initDeferredStartupData() async {
    try {
      await DefaultData.initDeferred();
    } catch (e, stack) {
      AppLog.e('Deferred init error: $e', error: e, stackTrace: stack);
    }
  }

  Future<void> _handleBackIntent() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressedAt == null ||
        now.difference(_lastBackPressedAt!) > _exitBackInterval) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('再按一次退出')));
      return;
    }

    await SystemNavigator.pop();
  }
}

class _MainDestination {
  const _MainDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;
}

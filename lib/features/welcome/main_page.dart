import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.book_outlined,
        'selectedIcon': Icons.book,
        'label': '書架',
        'page': const BookshelfPage(),
      },
      {
        'icon': Icons.explore_outlined,
        'selectedIcon': Icons.explore,
        'label': '發現',
        'page': const ExplorePage(),
      },
      {
        'icon': Icons.person_outline,
        'selectedIcon': Icons.person,
        'label': '我的',
        'page': const SettingsPage(),
      },
    ];

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackIntent();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: items.map((i) => i['page'] as Widget).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (_currentIndex == index) {
              if (DateTime.now().difference(_lastTapTime).inMilliseconds <
                  300) {
                final label = items[index]['label'];
                if (label == '書架') {
                  context.read<BookshelfProvider>().loadBooks();
                }
              }
              _lastTapTime = DateTime.now();
            }
            setState(() => _currentIndex = index);
          },
          destinations:
              items
                  .map(
                    (i) => NavigationDestination(
                      icon:
                          i['icon'] is Widget
                              ? i['icon']
                              : Icon(i['icon'] as IconData),
                      selectedIcon:
                          i['selectedIcon'] is Widget
                              ? i['selectedIcon']
                              : Icon(i['selectedIcon'] as IconData),
                      label: i['label'],
                    ),
                  )
                  .toList(),
        ),
      ),
    );
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

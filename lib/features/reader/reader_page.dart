import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/features/settings/settings_page.dart';
import 'package:legado_reader/features/replace_rule/replace_rule_page.dart';
import 'package:legado_reader/features/search/search_page.dart';
import 'widgets/reader/reader_top_menu.dart';
import 'widgets/reader/reader_bottom_menu.dart';
import 'widgets/reader_brightness_bar.dart';
import 'widgets/reader_chapters_drawer.dart';
import 'widgets/reader_settings_sheets.dart';
import 'view/read_view_runtime.dart';
import 'tts_dialog.dart';
import 'auto_read_dialog.dart';
import 'package:legado_reader/core/constant/page_anim.dart';

class ReaderPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  final int chapterPos;
  const ReaderPage({super.key, required this.book, this.chapterIndex = 0, this.chapterPos = 0});
  @override State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late PageController _pageCtrl;
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 0);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override void dispose() { _pageCtrl.dispose(); super.dispose(); }

  void _handleTap(Offset pos, Size size, ReaderProvider p) {
    final x = pos.dx, y = pos.dy, w = size.width, h = size.height;
    int row = (y / (h / 3)).floor().clamp(0, 2);
    int col = (x / (w / 3)).floor().clamp(0, 2);
    _executeAction(p, p.clickActions[row * 3 + col]);
  }

  void _executeAction(ReaderProvider p, int action) {
    switch (action) {
      case 0: p.toggleControls(); break;
      case 1: p.nextPage(); break;
      case 2: p.prevPage(); break;
      case 3: p.nextChapter(); break;
      case 4: p.prevChapter(); break;
      case 5: p.toggleTts(); break;
      case 7: p.toggleBookmark(); break;
      default: p.toggleControls();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      body: Consumer<ReaderProvider>(builder: (context, p, _) {
        final pendingJump = p.consumePendingJump();
        if (pendingJump != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_pageCtrl.hasClients) return;
            if (_pageCtrl.page?.round() != pendingJump) {
              _pageCtrl.jumpToPage(pendingJump);
            }
          });
        }
        return Container(
          color: p.currentTheme.backgroundColor,
          child: Stack(children: [
            // 1. 底層自定義背景圖片 (對標 Android bgImage)
            if (p.currentTheme.backgroundImage != null && File(p.currentTheme.backgroundImage!).existsSync())
              Positioned.fill(
                child: Image.file(
                  File(p.currentTheme.backgroundImage!),
                  fit: BoxFit.cover,
                ),
              ),
            
            // 2. 背景模糊特效 (對標 Android backgroundBlur)
            if (p.currentTheme.backgroundImage != null && p.backgroundBlur > 0)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: p.backgroundBlur, sigmaY: p.backgroundBlur),
                  child: Container(color: Colors.black.withValues(alpha: 0.1)),
                ),
              ),

            ReadViewRuntime(provider: p, pageController: _pageCtrl),
            if (((p.pageTurnMode == PageAnim.scroll && p.chapterPagesCache.isNotEmpty) ||
                    (p.pageTurnMode != PageAnim.scroll && p.slidePages.isNotEmpty)) &&
                !p.isLoading)
              _buildPermanentInfo(p),
            Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTapUp: (d) => p.showControls ? p.toggleControls() : _handleTap(d.localPosition, MediaQuery.of(context).size, p))),
            IgnorePointer(child: Container(color: Colors.black.withValues(alpha: (1.0 - p.brightness).clamp(0.0, 0.8)))),
            ReaderTopMenu(provider: p, onMore: () => _showMore(context)),
            ReaderBrightnessBar(provider: p),
            ReaderBottomMenu(
              provider: p,
              onOpenDrawer: () => _key.currentState?.openDrawer(),
              onTts: () => TtsDialog.show(context),
              onInterface: () => ReaderSettingsSheets.showInterfaceSettings(context, p),
              onSettings: () => ReaderSettingsSheets.showMoreSettings(context, p),
              onAutoPage: () async {
                if (!p.isAutoPaging) p.toggleAutoPage();
                await AutoReadDialog.show(context);
              },
              onToggleDayNight: () => p.setTheme(p.themeIndex == 1 ? 0 : 1),
              onSearch: () {
                p.toggleControls();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
              },
              onReplaceRule: () {
                p.toggleControls();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReplaceRulePage()));
              },
            ),
          ]),
        );
      }),
      drawer: Consumer<ReaderProvider>(builder: (context, p, _) => ReaderChaptersDrawer(provider: p)),
    );
  }

  Widget _buildPermanentInfo(ReaderProvider p) => Positioned(
        bottom: 0, left: 0, right: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(p.book.name, style: TextStyle(color: p.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 10), overflow: TextOverflow.ellipsis)),
              Text(
                p.pageTurnMode == PageAnim.scroll
                    ? '${p.currentChapterIndex + 1}/${p.chapters.length}'
                    : '${p.currentPageIndex + 1}/${p.slidePages.length}',
                style: TextStyle(color: p.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 10),
              ),
              SizedBox(width: 60, child: Text('${(p.chapters.isEmpty ? 0 : p.currentChapterIndex / p.chapters.length * 100).toStringAsFixed(1)}%', textAlign: TextAlign.right, style: TextStyle(color: p.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 10))),
            ],
          ),
        ),
      );

  void _showMore(BuildContext context) => showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.rule), title: const Text('替換規則'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReplaceRulePage())); }),
          ListTile(leading: const Icon(Icons.settings), title: const Text('全域設定'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())); }),
        ])),
      );
}

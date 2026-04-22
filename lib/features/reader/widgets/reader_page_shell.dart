import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/reader_layout.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/widgets/reader/reader_bottom_menu.dart';
import 'package:inkpage_reader/features/reader/widgets/reader/reader_top_menu.dart';
import 'package:inkpage_reader/features/reader/widgets/reader_chapters_drawer.dart';

class ReaderPageShell extends StatelessWidget {
  const ReaderPageShell({
    super.key,
    required this.provider,
    required this.scaffoldKey,
    required this.content,
    required this.onExitIntent,
    required this.onMore,
    required this.onOpenDrawer,
    required this.onTts,
    required this.onInterface,
    required this.onSettings,
    required this.onAutoPage,
    required this.onToggleDayNight,
    required this.onSearch,
    required this.onReplaceRule,
  });

  final ReaderProvider provider;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget content;
  final VoidCallback onExitIntent;
  final VoidCallback onMore;
  final VoidCallback onOpenDrawer;
  final VoidCallback onTts;
  final VoidCallback onInterface;
  final VoidCallback onSettings;
  final VoidCallback onAutoPage;
  final VoidCallback onToggleDayNight;
  final VoidCallback onSearch;
  final VoidCallback onReplaceRule;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        onExitIntent();
      },
      child: Scaffold(
        key: scaffoldKey,
        body: Container(
          color: provider.currentTheme.backgroundColor,
          child: Stack(
            children: [
              Positioned.fill(child: content),
              if (_shouldShowPermanentInfo(provider))
                ReaderPermanentInfoBar(provider: provider),
              if (provider.showControls)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: provider.toggleControls,
                  ),
                ),
              ReaderTopMenu(
                provider: provider,
                onBack: onExitIntent,
                onMore: onMore,
              ),
              ReaderBottomMenu(
                provider: provider,
                onOpenDrawer: onOpenDrawer,
                onTts: onTts,
                onInterface: onInterface,
                onSettings: onSettings,
                onAutoPage: onAutoPage,
                onToggleDayNight: onToggleDayNight,
                onSearch: onSearch,
                onReplaceRule: onReplaceRule,
              ),
            ],
          ),
        ),
        drawer: ReaderChaptersDrawer(provider: provider),
      ),
    );
  }

  bool _shouldShowPermanentInfo(ReaderProvider provider) {
    final hasVisibleContent =
        (provider.pageTurnMode == PageAnim.scroll &&
            provider.chapterPagesCache.isNotEmpty) ||
        (provider.pageTurnMode != PageAnim.scroll &&
            provider.slidePages.isNotEmpty);
    return hasVisibleContent &&
        !provider.isLoading &&
        provider.showReadTitleAddition;
  }
}

class ReaderPermanentInfoBar extends StatelessWidget {
  const ReaderPermanentInfoBar({super.key, required this.provider});

  final ReaderProvider provider;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              provider.currentTheme.backgroundColor.withValues(alpha: 0.0),
              provider.currentTheme.backgroundColor.withValues(alpha: 0.88),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            kReaderPermanentInfoTopPadding,
            16,
            MediaQuery.of(context).padding.bottom +
                kReaderPermanentInfoBottomSpacing,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  provider.book.name,
                  style: TextStyle(
                    color: provider.currentTheme.textColor.withValues(
                      alpha: 0.5,
                    ),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                provider.displayPageLabel,
                style: TextStyle(
                  color: provider.currentTheme.textColor.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  provider.displayChapterPercentLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: provider.currentTheme.textColor.withValues(
                      alpha: 0.5,
                    ),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

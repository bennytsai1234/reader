import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/services/book_storage_service.dart';
import 'package:inkpage_reader/features/reader_v2/features/bookmark/reader_v2_bookmark_controller.dart';
import 'package:inkpage_reader/features/reader_v2/features/menu/reader_v2_menu_controller.dart';
import 'package:inkpage_reader/features/reader_v2/features/settings/reader_v2_settings_controller.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_style.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_render_page.dart';
import 'package:inkpage_reader/features/reader_v2/features/menu/reader_v2_tap_action.dart';
import 'package:inkpage_reader/features/reader_v2/application/coordinators/reader_v2_chapter_navigation_resolver.dart';
import 'package:inkpage_reader/features/reader_v2/application/coordinators/reader_v2_display_coordinator.dart';
import 'package:inkpage_reader/features/reader_v2/application/coordinators/reader_v2_page_exit_coordinator.dart';
import 'package:inkpage_reader/features/reader_v2/application/session/reader_v2_session_facade.dart';
import 'package:inkpage_reader/features/reader_v2/features/tts/reader_v2_tts_highlight.dart';
import 'package:inkpage_reader/features/reader_v2/features/tts/reader_v2_tts_sheet.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_viewport_controller.dart';
import 'package:inkpage_reader/features/reader_v2/features/menu/reader_v2_bottom_menu.dart';
import 'package:inkpage_reader/features/reader_v2/shell/reader_v2_chapters_drawer.dart';
import 'package:inkpage_reader/features/reader_v2/features/settings/reader_v2_settings_sheets.dart';
import 'package:inkpage_reader/features/reader_v2/shell/reader_v2_page_shell.dart';
import 'package:inkpage_reader/features/settings/settings_page.dart';
import 'package:inkpage_reader/shared/widgets/app_bottom_sheet.dart';
import 'package:inkpage_reader/features/reader_v2/features/auto_page/reader_v2_auto_page_controller.dart';
import 'package:inkpage_reader/features/reader_v2/application/dependencies/reader_v2_dependencies.dart';
import 'package:inkpage_reader/features/reader_v2/features/tts/reader_v2_tts_controller.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_engine.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_spec.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_location.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_open_target.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_progress_controller.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_runtime.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_state.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_screen.dart';
import 'package:inkpage_reader/features/reader_v2/features/replace_rule/reader_v2_replace_rule_sheet.dart';

class ReaderV2Page extends StatefulWidget {
  const ReaderV2Page({
    super.key,
    required this.book,
    this.openTarget,
    this.initialChapters = const <BookChapter>[],
  });

  final Book book;
  final ReaderV2OpenTarget? openTarget;
  final List<BookChapter> initialChapters;

  @override
  State<ReaderV2Page> createState() => _ReaderV2PageState();
}

class _ReaderV2PageState extends State<ReaderV2Page>
    implements ReaderV2ExitFlowDelegate {
  static const ReaderV2DisplayCoordinator _displayCoordinator =
      ReaderV2DisplayCoordinator();
  static const ReaderV2SessionFacade _sessionFacade = ReaderV2SessionFacade();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ReaderV2PageExitCoordinator _exitCoordinator =
      ReaderV2PageExitCoordinator();
  final ReaderV2ViewportController _viewportController =
      ReaderV2ViewportController();

  late final ReaderV2SettingsController _settings;
  late final ReaderV2MenuController _menu;
  late final ReaderV2Dependencies _dependencies;
  late final BookStorageService _bookStorageService;

  ReaderV2Runtime? _runtime;
  ReaderV2TtsController? _tts;
  ReaderV2AutoPageController? _autoPage;
  ReaderV2BookmarkController? _bookmark;
  Size? _lastViewportSize;
  String? _lastLayoutSignature;
  int _lastContentSettingsGeneration = 0;
  bool _opening = false;
  bool _followingTtsHighlight = false;
  ReaderV2TtsHighlight? _lastFollowedTtsHighlight;

  @override
  void initState() {
    super.initState();
    _settings =
        ReaderV2SettingsController()..addListener(_handleControllerChanged);
    _menu = ReaderV2MenuController()..addListener(_handleControllerChanged);
    _dependencies = ReaderV2Dependencies(
      book: widget.book,
      initialChapters: widget.initialChapters,
      currentChineseConvert: () => _settings.chineseConvert,
    );
    _bookStorageService = BookStorageService(
      bookDao: _dependencies.bookDao,
      chapterDao: _dependencies.chapterDao,
      contentDao: _dependencies.readerChapterContentDao,
      bookmarkDao: _dependencies.bookmarkDao,
    );
    _lastContentSettingsGeneration = _settings.contentSettingsGeneration;
    unawaited(_settings.loadSettings());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _settings.removeListener(_handleControllerChanged);
    _menu.removeListener(_handleControllerChanged);
    _autoPage?.removeListener(_handleControllerChanged);
    _tts?.removeListener(_handleControllerChanged);
    unawaited(_runtime?.flushProgress());
    _autoPage?.dispose();
    _tts?.dispose();
    _runtime?.dispose();
    _menu.dispose();
    _settings.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    _drainRuntimeNotice();
    _maybeFollowTtsHighlight();
    if (mounted) setState(() {});
  }

  ReaderV2Runtime _ensureRuntime(Size size, ReaderV2Style style) {
    final existing = _runtime;
    if (existing != null) return existing;

    final spec = _specFromStyle(size, style);
    final repository = _dependencies.createChapterRepository();
    final progressController = ReaderV2ProgressController(
      book: widget.book,
      repository: repository,
      bookDao: _dependencies.bookDao,
    );
    final initialLocation =
        widget.openTarget?.location ??
        ReaderV2Location(
          chapterIndex: widget.book.chapterIndex,
          charOffset: widget.book.charOffset,
          visualOffsetPx: widget.book.visualOffsetPx,
        );
    final runtime = ReaderV2Runtime(
      book: widget.book,
      repository: repository,
      layoutEngine: ReaderV2LayoutEngine(),
      progressController: progressController,
      initialLayoutSpec: spec,
      initialMode: _modeFor(_settings.pageTurnMode),
      initialLocation: initialLocation,
    )..addListener(_handleControllerChanged);
    final tts = ReaderV2TtsController(runtime: runtime)
      ..addListener(_handleControllerChanged);
    final autoPage = ReaderV2AutoPageController(
      runtime: runtime,
      viewportController: _viewportController,
      viewportExtent:
          () =>
              _lastViewportSize?.height ??
              runtime.state.layoutSpec.viewportSize.height,
    )..addListener(_handleControllerChanged);
    _runtime = runtime;
    _tts = tts;
    _autoPage = autoPage;
    final bookmarkDao = _dependencies.bookmarkDao;
    if (bookmarkDao != null) {
      _bookmark = ReaderV2BookmarkController(
        book: widget.book,
        runtime: runtime,
        bookmarkDao: bookmarkDao,
      );
    }
    _lastLayoutSignature = spec.layoutSignature;
    unawaited(tts.loadSettings());

    if (!_opening) {
      _opening = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(runtime.openBook().whenComplete(() => _opening = false));
      });
    }
    return runtime;
  }

  ReaderV2Mode _modeFor(int pageTurnMode) {
    return pageTurnMode == ReaderV2PageMode.scroll.pageAnim
        ? ReaderV2Mode.scroll
        : ReaderV2Mode.slide;
  }

  ReaderV2LayoutSpec _specFromStyle(Size size, ReaderV2Style style) {
    return ReaderV2LayoutSpec.fromViewport(
      viewportSize: size,
      style: ReaderV2LayoutStyle(
        fontSize: style.fontSize,
        lineHeight: style.lineHeight,
        letterSpacing: style.letterSpacing,
        paragraphSpacing: style.paragraphSpacing,
        paddingTop: style.paddingTop,
        paddingBottom: style.paddingBottom,
        paddingLeft: style.paddingLeft,
        paddingRight: style.paddingRight,
        fontFamily: style.fontFamily,
        bold: style.bold,
        textIndent: style.textIndent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _settings.currentTheme;
    final isDarkBackground = theme.backgroundColor.computeLuminance() < 0.5;
    final runtime = _runtime;
    final page = _currentPage(runtime);
    final chapterIndex = _currentChapterIndex(runtime);
    final navigation = ReaderV2ChapterNavigationState(
      chapterCount: runtime?.chapterCount ?? widget.initialChapters.length,
      currentIndex: chapterIndex,
      isScrubbing: _menu.isScrubbing,
      scrubIndex: _menu.scrubIndex,
      pendingIndex: _menu.pendingChapterNavigationIndex,
      titleFor: _chapterTitleAt,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkBackground ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDarkBackground ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkBackground ? Brightness.light : Brightness.dark,
      ),
      child: ReaderV2PageShell(
        book: widget.book,
        scaffoldKey: _scaffoldKey,
        content: _buildContent(context),
        drawer: ReaderV2ChaptersDrawer(
          chapters: runtime?.chapters ?? widget.initialChapters,
          currentChapterIndex: chapterIndex,
          titleFor: _chapterTitleAt,
          listenable: runtime,
          onChapterTap: _jumpToChapter,
        ),
        backgroundColor: theme.backgroundColor,
        textColor: theme.textColor,
        controlsVisible: _menu.controlsVisible,
        readBarStyleFollowPage: _settings.readBarStyleFollowPage,
        showReadTitleAddition: _settings.showReadTitleAddition,
        hasVisibleContent: page != null,
        isLoading:
            runtime == null || runtime.state.phase != ReaderV2Phase.ready,
        chapterTitle: _chapterTitleAt(chapterIndex),
        chapterUrl: _chapterUrlAt(chapterIndex),
        originName: widget.book.originName,
        displayPageLabel: _displayPageLabel(runtime, page),
        displayChapterPercentLabel: _displayChapterPercentLabel(runtime, page),
        navigation: navigation,
        isAutoPaging: _autoPage?.isRunning ?? false,
        dayNightIcon: _settings.dayNightToggleIcon,
        dayNightTooltip: _settings.dayNightToggleTooltip,
        onExitIntent: _handleExitIntent,
        onMore: _showMore,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onTts: _showTts,
        onInterface:
            () => ReaderV2SettingsSheets.showInterfaceSettings(
              context,
              _settings,
            ),
        onSettings:
            () =>
                ReaderV2SettingsSheets.showAdvancedSettings(context, _settings),
        onAutoPage: _toggleAutoPage,
        onToggleDayNight: _settings.toggleDayNightTheme,
        onReplaceRule: _openReplaceRule,
        onToggleControls: _menu.toggleControls,
        onPrevChapter: () => unawaited(_jumpRelativeChapter(-1)),
        onNextChapter: () => unawaited(_jumpRelativeChapter(1)),
        onScrubStart: () => _menu.onScrubStart(chapterIndex),
        onScrubbing: _menu.onScrubbing,
        onScrubEnd: (index) {
          _menu.onScrubEnd(index);
          unawaited(_jumpToChapter(index));
        },
        showTts: true,
        showAutoPage: true,
        showReplaceRule: true,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final mediaPadding = MediaQuery.paddingOf(context);
        _lastViewportSize = size;

        final style = _settings.readStyleFor(
          mediaPadding,
          bottomInfoReservedExternally: _settings.showReadTitleAddition,
        );
        final runtime = _ensureRuntime(size, style);
        _syncRuntimeConfiguration(runtime, size, style);

        final theme = _settings.currentTheme;
        return EngineReaderV2Screen(
          runtime: runtime,
          backgroundColor: theme.backgroundColor,
          textColor: theme.textColor,
          style: style,
          viewportController: _viewportController,
          ttsHighlight: _tts?.currentHighlight,
          onContentTapUp:
              _menu.controlsVisible ? null : (details) => _handleTap(details),
        );
      },
    );
  }

  void _syncRuntimeConfiguration(
    ReaderV2Runtime runtime,
    Size size,
    ReaderV2Style style,
  ) {
    final spec = _specFromStyle(size, style);
    final targetMode = _modeFor(_settings.pageTurnMode);
    final needsLayout = _lastLayoutSignature != spec.layoutSignature;
    final needsMode = runtime.state.mode != targetMode;
    if (needsLayout || needsMode) {
      _lastLayoutSignature = spec.layoutSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(runtime.applyPresentation(spec: spec, mode: targetMode));
      });
    }
    if (_lastContentSettingsGeneration != _settings.contentSettingsGeneration) {
      _lastContentSettingsGeneration = _settings.contentSettingsGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(runtime.reloadContentPreservingLocation());
      });
    }
  }

  void _handleTap(TapUpDetails details) {
    final size = _lastViewportSize;
    final runtime = _runtime;
    if (size == null || runtime == null) return;
    final row = (details.localPosition.dy / (size.height / 3)).floor().clamp(
      0,
      2,
    );
    final col = (details.localPosition.dx / (size.width / 3)).floor().clamp(
      0,
      2,
    );
    final action = ReaderV2TapAction.fromCode(
      _settings.clickActions[row * 3 + col],
    );
    switch (action) {
      case ReaderV2TapAction.menu:
        _menu.toggleControls();
        return;
      case ReaderV2TapAction.nextPage:
        if (runtime.state.mode == ReaderV2Mode.scroll &&
            _viewportController.animateBy != null) {
          unawaited(_viewportController.animateBy!(size.height * 0.9));
        } else if (runtime.state.mode == ReaderV2Mode.slide &&
            _viewportController.moveToNextPage != null) {
          unawaited(_viewportController.moveToNextPage!());
        } else if (runtime.state.mode == ReaderV2Mode.slide) {
          runtime.moveSlidePageAndSettle(forward: true);
        } else {
          runtime.moveToNextPage();
        }
        return;
      case ReaderV2TapAction.prevPage:
        if (runtime.state.mode == ReaderV2Mode.scroll &&
            _viewportController.animateBy != null) {
          unawaited(_viewportController.animateBy!(-size.height * 0.9));
        } else if (runtime.state.mode == ReaderV2Mode.slide &&
            _viewportController.moveToPrevPage != null) {
          unawaited(_viewportController.moveToPrevPage!());
        } else if (runtime.state.mode == ReaderV2Mode.slide) {
          runtime.moveSlidePageAndSettle(forward: false);
        } else {
          runtime.moveToPrevPage();
        }
        return;
      case ReaderV2TapAction.nextChapter:
        unawaited(_jumpRelativeChapter(1));
        return;
      case ReaderV2TapAction.prevChapter:
        unawaited(_jumpRelativeChapter(-1));
        return;
      case ReaderV2TapAction.toggleTts:
        unawaited(_tts?.toggle());
        return;
      case ReaderV2TapAction.bookmark:
        unawaited(_toggleBookmark());
        return;
    }
  }

  Future<void> _jumpRelativeChapter(int delta) async {
    final runtime = _runtime;
    if (runtime == null || runtime.chapterCount <= 0) return;
    final target = ReaderV2ChapterNavigationResolver.resolveRelativeTarget(
      currentChapterIndex: runtime.state.visibleLocation.chapterIndex,
      chapterCount: runtime.chapterCount,
      delta: delta,
    );
    if (target == null) {
      _showNotice(delta < 0 ? '已經是第一章' : '已經是最後一章');
      return;
    }
    await _jumpToChapter(target);
  }

  Future<void> _jumpToChapter(int index) async {
    final runtime = _runtime;
    if (runtime == null) return;
    final safeIndex =
        index.clamp(0, (runtime.chapterCount - 1).clamp(0, 1 << 20)).toInt();
    await runtime.jumpToChapter(safeIndex);
    _menu.completeChapterNavigation();
  }

  void _drainRuntimeNotice() {
    final notice = _runtime?.takeUserNotice();
    if (!mounted || notice == null || notice.isEmpty) return;
    _showNotice(notice);
  }

  void _showNotice(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!mounted || messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleExitIntent() {
    unawaited(
      _exitCoordinator.handleExitIntent(
        context: context,
        provider: this,
        isDrawerOpen: () => _scaffoldKey.currentState?.isDrawerOpen ?? false,
        popNavigator: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showMore() {
    AppBottomSheet.show(
      context: context,
      title: '更多操作',
      icon: Icons.more_horiz_rounded,
      children: [
        ListTile(
          leading: const Icon(Icons.settings_suggest_rounded),
          title: const Text('全域系統設定'),
          subtitle: const Text('備份、還原與解析引擎配置'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }

  void _toggleAutoPage() {
    final autoPage = _autoPage;
    if (autoPage == null) return;
    if (!autoPage.isRunning) _menu.hideControlsForAutoPage();
    autoPage.toggle();
  }

  void _maybeFollowTtsHighlight() {
    if (_followingTtsHighlight) return;
    final highlight = _tts?.currentHighlight;
    if (highlight == null || !highlight.isValid) {
      _lastFollowedTtsHighlight = null;
      return;
    }
    if (highlight == _lastFollowedTtsHighlight) return;
    final ensureVisible = _viewportController.ensureCharRangeVisible;
    if (ensureVisible == null) return;

    _lastFollowedTtsHighlight = highlight;
    _followingTtsHighlight = true;
    unawaited(
      ensureVisible(
        chapterIndex: highlight.chapterIndex,
        startCharOffset: highlight.highlightStart,
        endCharOffset: highlight.highlightEnd,
      ).whenComplete(() {
        _followingTtsHighlight = false;
      }),
    );
  }

  void _showTts() {
    final tts = _tts;
    if (tts == null) return;
    ReaderV2TtsSheet.show(context, tts: tts);
  }

  void _openReplaceRule() {
    _menu.dismissControls();
    final replaceDao = _dependencies.replaceDao;
    if (replaceDao == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('替換規則資料庫不可用')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => ReaderV2ReplaceRuleSheet(
            book: widget.book,
            bookDao: _dependencies.bookDao,
            replaceDao: replaceDao,
            onReload: () async {
              await _runtime?.reloadContentPreservingLocation();
            },
          ),
    );
  }

  Future<void> _toggleBookmark() async {
    final bookmark = _bookmark;
    if (bookmark == null) {
      _showNotice('書籤資料庫不可用');
      return;
    }
    await bookmark.addVisibleLocationBookmark();
    _showNotice('已加入書籤');
  }

  @override
  Book get book => widget.book;

  @override
  bool shouldPromptAddToBookshelfOnExit() {
    return !widget.book.isInBookshelf && _settings.showAddToShelfAlert;
  }

  @override
  Future<void> persistExitProgress() async {
    await _runtime?.flushProgress();
  }

  @override
  Future<void> addCurrentBookToBookshelf() async {
    final runtime = _runtime;
    final location =
        runtime?.state.visibleLocation ??
        ReaderV2Location(
          chapterIndex: widget.book.chapterIndex,
          charOffset: widget.book.charOffset,
          visualOffsetPx: widget.book.visualOffsetPx,
        );
    final chapters = runtime?.chapters ?? widget.initialChapters;
    await _sessionFacade.addCurrentBookToBookshelf(
      book: widget.book,
      chapters: chapters,
      location: location,
      chapterTitle: _chapterTitleAt(location.chapterIndex),
      bookDao: _dependencies.bookDao,
      chapterDao: _dependencies.chapterDao,
    );
    if (mounted) setState(() {});
  }

  @override
  Future<void> discardUnkeptBookStorage() {
    return _bookStorageService.discardBook(widget.book);
  }

  int _currentChapterIndex(ReaderV2Runtime? runtime) {
    final count = runtime?.chapterCount ?? widget.initialChapters.length;
    if (runtime == null || count <= 0) return 0;
    return runtime.state.visibleLocation.chapterIndex
        .clamp(0, count - 1)
        .toInt();
  }

  ReaderV2RenderPage? _currentPage(ReaderV2Runtime? runtime) {
    if (runtime == null) return null;
    return runtime.state.pageWindow?.current ?? runtime.state.currentSlidePage;
  }

  String _chapterTitleAt(int index) {
    final runtime = _runtime;
    if (runtime != null) return runtime.titleFor(index);
    if (index < 0 || index >= widget.initialChapters.length) return '';
    return widget.initialChapters[index].title;
  }

  String _chapterUrlAt(int index) {
    final runtime = _runtime;
    if (runtime != null) return runtime.chapterUrlAt(index);
    if (index < 0 || index >= widget.initialChapters.length) return '';
    return widget.initialChapters[index].url;
  }

  String _displayPageLabel(ReaderV2Runtime? runtime, ReaderV2RenderPage? page) {
    if (runtime == null) return '0/0';
    if (runtime.state.mode == ReaderV2Mode.scroll) {
      final visiblePage = _visiblePageForScroll(runtime);
      if (visiblePage != null && visiblePage.pageSize > 0) {
        return _displayCoordinator.formatPageLabel(
          visiblePage.pageIndex,
          visiblePage.pageSize,
        );
      }
      return '0/0';
    }
    if (page == null || page.pageSize <= 0) return '0/0';
    return _displayCoordinator.formatPageLabel(page.pageIndex, page.pageSize);
  }

  String _displayChapterPercentLabel(
    ReaderV2Runtime? runtime,
    ReaderV2RenderPage? page,
  ) {
    if (runtime == null) return '0.0%';
    if (runtime.state.mode == ReaderV2Mode.scroll) {
      return _visiblePageForScroll(runtime)?.readProgress ?? '0.0%';
    }
    if (page == null) return '0.0%';
    return page.readProgress;
  }

  ReaderV2RenderPage? _visiblePageForScroll(ReaderV2Runtime runtime) {
    final location = runtime.state.visibleLocation.normalized(
      chapterCount: runtime.chapterCount,
    );
    final layout = runtime.debugResolver.cachedLayout(location.chapterIndex);
    if (layout == null || layout.pages.isEmpty) return null;
    return layout.pageForCharOffset(location.charOffset);
  }
}

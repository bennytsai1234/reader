import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/features/reader_v2/features/menu/reader_v2_bottom_menu.dart';
import 'package:inkpage_reader/features/reader_v2/shell/reader_v2_chapters_drawer.dart';
import 'package:inkpage_reader/features/reader_v2/shell/reader_v2_page_shell.dart';

void main() {
  testWidgets('controls overlay tap should not pass through content', (
    tester,
  ) async {
    var toggleCalls = 0;
    var contentTapCalls = 0;

    final shell = MaterialApp(
      home: ReaderV2PageShell(
        book: Book(bookUrl: 'test://book', name: '測試書', originName: '本地'),
        scaffoldKey: GlobalKey<ScaffoldState>(),
        content: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => contentTapCalls += 1,
          child: const SizedBox.expand(),
        ),
        drawer: ReaderV2ChaptersDrawer(
          chapters: const [],
          currentChapterIndex: 0,
          titleFor: (_) => '',
          onChapterTap: (_) async {},
        ),
        backgroundColor: Colors.white,
        textColor: Colors.black,
        controlsVisible: true,
        readBarStyleFollowPage: true,
        showReadTitleAddition: false,
        hasVisibleContent: true,
        isLoading: false,
        chapterTitle: '第一章',
        chapterUrl: '',
        originName: '本地',
        displayPageLabel: '1/1',
        displayChapterPercentLabel: '10%',
        navigation: ReaderV2ChapterNavigationState(
          chapterCount: 1,
          currentIndex: 0,
          isScrubbing: false,
          scrubIndex: 0,
          pendingIndex: null,
          titleFor: (_) => '',
        ),
        isAutoPaging: false,
        dayNightIcon: Icons.light_mode,
        dayNightTooltip: '日夜切換',
        onExitIntent: () {},
        onMore: () {},
        onOpenDrawer: () {},
        onTts: () {},
        onInterface: () {},
        onSettings: () {},
        onAutoPage: () {},
        onToggleDayNight: () {},
        onReplaceRule: () {},
        onToggleControls: () => toggleCalls += 1,
        onPrevChapter: () {},
        onNextChapter: () {},
        onScrubStart: () {},
        onScrubbing: (_) {},
        onScrubEnd: (_) {},
      ),
    );

    await tester.pumpWidget(shell);
    await tester.tapAt(const Offset(120, 220));
    await tester.pump();

    expect(toggleCalls, 1);
    expect(contentTapCalls, 0);
  });

  testWidgets('permanent info bar tap toggles controls', (tester) async {
    var toggleCalls = 0;
    var contentTapCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ReaderV2PageShell(
          book: Book(bookUrl: 'test://book', name: '測試書', originName: '本地'),
          scaffoldKey: GlobalKey<ScaffoldState>(),
          content: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => contentTapCalls += 1,
            child: const SizedBox.expand(),
          ),
          drawer: ReaderV2ChaptersDrawer(
            chapters: const [],
            currentChapterIndex: 0,
            titleFor: (_) => '',
            onChapterTap: (_) async {},
          ),
          backgroundColor: Colors.white,
          textColor: Colors.black,
          controlsVisible: false,
          readBarStyleFollowPage: true,
          showReadTitleAddition: true,
          hasVisibleContent: true,
          isLoading: false,
          chapterTitle: '第一章',
          chapterUrl: '',
          originName: '本地',
          displayPageLabel: '1/1',
          displayChapterPercentLabel: '10%',
          navigation: ReaderV2ChapterNavigationState(
            chapterCount: 1,
            currentIndex: 0,
            isScrubbing: false,
            scrubIndex: 0,
            pendingIndex: null,
            titleFor: (_) => '',
          ),
          isAutoPaging: false,
          dayNightIcon: Icons.light_mode,
          dayNightTooltip: '日夜切換',
          onExitIntent: () {},
          onMore: () {},
          onOpenDrawer: () {},
          onTts: () {},
          onInterface: () {},
          onSettings: () {},
          onAutoPage: () {},
          onToggleDayNight: () {},
          onReplaceRule: () {},
          onToggleControls: () => toggleCalls += 1,
          onPrevChapter: () {},
          onNextChapter: () {},
          onScrubStart: () {},
          onScrubbing: (_) {},
          onScrubEnd: (_) {},
        ),
      ),
    );

    final scaffoldSize = tester.getSize(find.byType(Scaffold));
    await tester.tapAt(Offset(scaffoldSize.width / 2, scaffoldSize.height - 8));
    await tester.pump();

    expect(toggleCalls, 1);
    expect(contentTapCalls, 0);
  });
}

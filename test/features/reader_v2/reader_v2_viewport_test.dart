import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader_v2/content/reader_v2_chapter_repository.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_engine.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_spec.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_style.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_location.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_progress_controller.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_runtime.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_state.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/reader_v2_viewport_controller.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/scroll_reader_v2_viewport.dart';
import 'package:inkpage_reader/features/reader_v2/viewport/slide_reader_v2_viewport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scroll viewport syncs to runtime location changes', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.scroll,
      chapterCount: 3,
      paragraphsPerChapter: 18,
    );
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: ScrollReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: ReaderV2ViewportController(),
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    expect(runtime.captureVisibleLocation()?.chapterIndex, 0);

    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 1, charOffset: 24),
      immediateSave: false,
    );
    await _pumpViewport(tester);

    expect(runtime.captureVisibleLocation()?.chapterIndex, 1);

    runtime.dispose();
  });

  testWidgets(
    'scroll viewport ensureCharRangeVisible accepts visible TTS range',
    (tester) async {
      final runtime = _runtime(
        initialMode: ReaderV2Mode.scroll,
        chapterCount: 2,
        paragraphsPerChapter: 12,
      );
      final controller = ReaderV2ViewportController();
      await runtime.jumpToLocation(
        const ReaderV2Location(chapterIndex: 0, charOffset: 0),
        immediateSave: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 260,
            height: 360,
            child: ScrollReaderV2Viewport(
              runtime: runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(),
              controller: controller,
            ),
          ),
        ),
      );
      await _pumpViewport(tester);

      final ensureVisible = controller.ensureCharRangeVisible;
      expect(ensureVisible, isNotNull);
      final captured = runtime.captureVisibleLocation();
      expect(captured, isNotNull);
      final visible = await ensureVisible!(
        chapterIndex: captured!.chapterIndex,
        startCharOffset: captured.charOffset,
        endCharOffset: captured.charOffset + 6,
      );

      expect(visible, isTrue);

      runtime.dispose();
    },
  );

  testWidgets('slide viewport ensureCharRangeVisible jumps to TTS page', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 3,
      paragraphsPerChapter: 10,
    );
    final controller = ReaderV2ViewportController();
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: SlideReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: controller,
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    final ensureVisible = controller.ensureCharRangeVisible;
    expect(ensureVisible, isNotNull);
    final moved = await ensureVisible!(
      chapterIndex: 1,
      startCharOffset: 8,
      endCharOffset: 16,
    );
    await _pumpViewport(tester);

    expect(moved, isTrue);
    expect(runtime.state.pageWindow?.current.chapterIndex, 1);

    runtime.dispose();
  });

  testWidgets('slide viewport syncs to runtime location changes', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 3,
      paragraphsPerChapter: 10,
    );
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: SlideReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: ReaderV2ViewportController(),
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 2, charOffset: 12),
      immediateSave: false,
    );
    await _pumpViewport(tester);

    expect(runtime.captureVisibleLocation()?.chapterIndex, 2);

    runtime.dispose();
  });

  testWidgets('slide viewport shows placeholders at book edges', (
    tester,
  ) async {
    final runtime = _runtime(
      initialMode: ReaderV2Mode.slide,
      chapterCount: 1,
      paragraphsPerChapter: 1,
    );
    await runtime.jumpToLocation(
      const ReaderV2Location(chapterIndex: 0, charOffset: 0),
      immediateSave: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 260,
          height: 360,
          child: SlideReaderV2Viewport(
            runtime: runtime,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            style: _style(),
            controller: ReaderV2ViewportController(),
          ),
        ),
      ),
    );
    await _pumpViewport(tester);

    expect(find.text('已經是第一頁'), findsOneWidget);
    expect(find.text('已經是最後一頁'), findsOneWidget);

    runtime.dispose();
  });
}

Future<void> _pumpViewport(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 16));
}

ReaderV2Runtime _runtime({
  required ReaderV2Mode initialMode,
  required int chapterCount,
  required int paragraphsPerChapter,
}) {
  final book = Book(
    bookUrl: 'test://viewport',
    origin: 'local',
    originName: 'fixture',
    name: '測試書',
  );
  final chapters = _chapters(
    bookUrl: book.bookUrl,
    count: chapterCount,
    paragraphsPerChapter: paragraphsPerChapter,
  );
  final repository = ReaderV2ChapterRepository(
    book: book,
    initialChapters: chapters,
    bookDao: _FakeBookDao(),
    chapterDao: _FakeChapterDao(chapters),
    sourceDao: _FakeSourceDao(),
    contentDao: null,
  );
  return ReaderV2Runtime(
    book: book,
    repository: repository,
    layoutEngine: ReaderV2LayoutEngine(),
    progressController: ReaderV2ProgressController(
      book: book,
      repository: repository,
      bookDao: _FakeBookDao(),
    ),
    initialLayoutSpec: _spec(),
    initialMode: initialMode,
    initialLocation: const ReaderV2Location(chapterIndex: 0, charOffset: 0),
  );
}

List<BookChapter> _chapters({
  required String bookUrl,
  required int count,
  required int paragraphsPerChapter,
}) {
  return List<BookChapter>.generate(count, (index) {
    return BookChapter(
      index: index,
      bookUrl: bookUrl,
      title: '第${index + 1}章',
      content: List<String>.filled(
        paragraphsPerChapter,
        '這是第${index + 1}章的測試內容，用於建立 viewport 測試所需的文字。',
      ).join('\n\n'),
    );
  });
}

ReaderV2LayoutSpec _spec() {
  return ReaderV2LayoutSpec.fromViewport(
    viewportSize: const Size(260, 360),
    style: ReaderV2LayoutStyle(
      fontSize: 18,
      lineHeight: 1.5,
      letterSpacing: 0,
      paragraphSpacing: 0.8,
      paddingTop: 12,
      paddingBottom: 12,
      paddingLeft: 12,
      paddingRight: 12,
      textIndent: 2,
    ),
  );
}

ReaderV2Style _style() {
  return const ReaderV2Style(
    fontSize: 18,
    lineHeight: 1.5,
    letterSpacing: 0,
    paragraphSpacing: 0.8,
    paddingTop: 12,
    paddingBottom: 12,
    paddingLeft: 12,
    paddingRight: 12,
    textIndent: 2,
    pageMode: ReaderV2PageMode.slide,
  );
}

class _FakeBookDao extends Fake implements BookDao {
  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos, {
    double visualOffsetPx = 0.0,
    String? readerAnchorJson,
  }) async {}
}

class _FakeChapterDao extends Fake implements ChapterDao {
  _FakeChapterDao(this.storedChapters);

  final List<BookChapter> storedChapters;

  @override
  Future<List<BookChapter>> getByBook(String bookUrl) async => storedChapters;
}

class _FakeSourceDao extends Fake implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;
}

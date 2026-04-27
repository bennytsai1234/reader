import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_repository.dart';
import 'package:inkpage_reader/features/reader/engine/layout_engine.dart';
import 'package:inkpage_reader/features/reader/engine/layout_spec.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_controller.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_runtime.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_state.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_tile_painter.dart';
import 'package:inkpage_reader/features/reader/viewport/scroll_reader_viewport.dart';
import 'package:inkpage_reader/features/reader/viewport/slide_reader_viewport.dart';

class _FakeBookDao extends Fake implements BookDao {
  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos, {
    String? readerAnchorJson,
  }) async {}
}

class _FakeChapterDao extends Fake implements ChapterDao {
  _FakeChapterDao(this.chapterList);

  final List<BookChapter> chapterList;

  @override
  Future<List<BookChapter>> getByBook(String bookUrl) async => chapterList;
}

class _FakeSourceDao extends Fake implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;
}

class _FakeContentDao extends Fake implements ReaderChapterContentDao {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tile-based reader viewports', () {
    testWidgets('scroll drag updates transform without repainting tiles', (
      tester,
    ) async {
      final env = _RuntimeEnv();
      await env.runtime.openBook();

      var paints = 0;
      ReaderTilePainter.debugOnPaint = (_) {
        paints += 1;
      };
      addTearDown(() {
        ReaderTilePainter.debugOnPaint = null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: ScrollReaderViewport(
              runtime: env.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.scroll),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialPaints = paints;
      await tester.drag(
        find.byType(ScrollReaderViewport),
        const Offset(0, -40),
      );
      await tester.pump();

      expect(paints, initialPaints);

      await env.runtime.flushProgress();
      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('slide recenters before committing the next tile window', (
      tester,
    ) async {
      final env = _RuntimeEnv(mode: ReaderMode.slide);
      await env.runtime.openBook();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 360,
            child: SlideReaderViewport(
              runtime: env.runtime,
              backgroundColor: Colors.white,
              textColor: Colors.black,
              style: _style(ReaderPageMode.slide),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = env.runtime.state.pageWindow!.current;
      final pageView = tester.widget<PageView>(find.byType(PageView));

      pageView.controller!.jumpToPage(2);
      await tester.pump();

      expect(env.runtime.state.pageWindow!.current.pageIndex, before.pageIndex);
      expect(
        env.runtime.state.pageWindow!.current.chapterIndex,
        before.chapterIndex,
      );

      await tester.pump();

      expect(
        '${env.runtime.state.pageWindow!.current.chapterIndex}:${env.runtime.state.pageWindow!.current.pageIndex}',
        isNot('${before.chapterIndex}:${before.pageIndex}'),
      );

      await env.runtime.flushProgress();
      env.runtime.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}

class _RuntimeEnv {
  _RuntimeEnv({ReaderMode mode = ReaderMode.scroll})
    : book = Book(
        bookUrl: 'book',
        origin: 'local',
        name: '測試書',
        chapterIndex: 0,
        charOffset: 0,
      ),
      bookDao = _FakeBookDao() {
    final chapters = _chaptersFor(book.bookUrl, 4);
    repository = ChapterRepository(
      book: book,
      initialChapters: chapters,
      bookDao: bookDao,
      chapterDao: _FakeChapterDao(chapters),
      sourceDao: _FakeSourceDao(),
      contentDao: _FakeContentDao(),
    );
    runtime = ReaderRuntime(
      book: book,
      repository: repository,
      layoutEngine: LayoutEngine(),
      progressController: ReaderProgressController(
        book: book,
        repository: repository,
        bookDao: bookDao,
      ),
      initialLayoutSpec: _spec(),
      initialMode: mode,
    );
  }

  final Book book;
  final _FakeBookDao bookDao;
  late final ChapterRepository repository;
  late final ReaderRuntime runtime;
}

List<BookChapter> _chaptersFor(String bookUrl, int count) {
  return List<BookChapter>.generate(count, (chapterIndex) {
    return BookChapter(
      title: '第$chapterIndex章',
      index: chapterIndex,
      bookUrl: bookUrl,
      content: List<String>.generate(
        40,
        (i) => '第$chapterIndex章第$i段，這是一段足夠長的文字，用於產生多個 TextPage。',
      ).join('\n\n'),
    );
  });
}

LayoutSpec _spec() {
  return LayoutSpec.fromViewport(
    viewportSize: const Size(320, 360),
    style: _style(ReaderPageMode.scroll),
  );
}

ReadStyle _style(ReaderPageMode mode) {
  return ReadStyle(
    fontSize: 18,
    lineHeight: 1.5,
    letterSpacing: 0,
    paragraphSpacing: 0.6,
    paddingTop: 12,
    paddingBottom: 12,
    paddingLeft: 16,
    paddingRight: 16,
    textIndent: 2,
    textFullJustify: true,
    pageMode: mode,
  );
}

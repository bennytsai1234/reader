import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader_v2/content/reader_v2_chapter_repository.dart';
import 'package:inkpage_reader/features/reader_v2/content/reader_v2_content.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_engine.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout_spec.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_location.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_progress_controller.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_resolver.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_runtime.dart';
import 'package:inkpage_reader/features/reader_v2/runtime/reader_v2_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderV2Resolver', () {
    test('reuses cached layouts and invalidates them by generation', () async {
      final engine = _CountingLayoutEngine();
      final resolver = ReaderV2Resolver(
        repository: _repository(),
        layoutEngine: engine,
        layoutSpec: _spec(fontSize: 18),
      );

      final first = await resolver.ensureLayout(0);
      final second = await resolver.ensureLayout(0);
      expect(identical(first, second), isTrue);
      expect(engine.layoutCount, 1);

      resolver.updateLayoutSpec(_spec(fontSize: 22));
      final third = await resolver.ensureLayout(0);
      expect(identical(first, third), isFalse);
      expect(engine.layoutCount, 2);

      resolver.clearCachedLayouts();
      await resolver.ensureLayout(0);
      expect(engine.layoutCount, 3);
    });
  });

  group('ReaderV2Runtime', () {
    test(
      'jumpToLocation resolves a page window and visible location',
      () async {
        final runtime = _runtime(initialMode: ReaderV2Mode.slide);

        await runtime.jumpToLocation(
          const ReaderV2Location(chapterIndex: 1, charOffset: 12),
          immediateSave: false,
        );

        expect(runtime.state.phase, ReaderV2Phase.ready);
        expect(runtime.state.visibleLocation.chapterIndex, 1);
        expect(runtime.state.pageWindow, isNotNull);
        expect(runtime.state.pageWindow!.current.chapterIndex, 1);
        expect(runtime.state.currentSlidePage?.chapterIndex, 1);

        runtime.dispose();
      },
    );

    test('applyPresentation keeps location while changing mode/spec', () async {
      final runtime = _runtime(initialMode: ReaderV2Mode.slide);
      await runtime.jumpToLocation(
        const ReaderV2Location(chapterIndex: 0, charOffset: 20),
        immediateSave: false,
      );
      final before = runtime.state.visibleLocation;
      final beforeGeneration = runtime.state.layoutGeneration;

      await runtime.applyPresentation(
        spec: _spec(fontSize: 22),
        mode: ReaderV2Mode.scroll,
      );

      expect(runtime.state.phase, ReaderV2Phase.ready);
      expect(runtime.state.mode, ReaderV2Mode.scroll);
      expect(runtime.state.visibleLocation.chapterIndex, before.chapterIndex);
      expect(runtime.state.visibleLocation.charOffset, before.charOffset);
      expect(runtime.state.layoutGeneration, greaterThan(beforeGeneration));

      runtime.dispose();
    });

    test(
      'reloadContentPreservingLocation clears caches and restores anchor',
      () async {
        final runtime = _runtime(initialMode: ReaderV2Mode.scroll);
        await runtime.jumpToLocation(
          const ReaderV2Location(chapterIndex: 1, charOffset: 18),
          immediateSave: false,
        );
        final before = runtime.state.visibleLocation;
        final beforeGeneration = runtime.state.layoutGeneration;

        await runtime.reloadContentPreservingLocation();

        expect(runtime.state.phase, ReaderV2Phase.ready);
        expect(runtime.state.visibleLocation.chapterIndex, before.chapterIndex);
        expect(runtime.state.visibleLocation.charOffset, before.charOffset);
        expect(runtime.state.layoutGeneration, greaterThan(beforeGeneration));

        runtime.dispose();
      },
    );
  });
}

ReaderV2Runtime _runtime({required ReaderV2Mode initialMode}) {
  final book = _book();
  final repository = _repository(book: book);
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

ReaderV2ChapterRepository _repository({Book? book}) {
  final targetBook = book ?? _book();
  return ReaderV2ChapterRepository(
    book: targetBook,
    initialChapters: _chapters(targetBook.bookUrl),
    bookDao: _FakeBookDao(),
    chapterDao: _FakeChapterDao(_chapters(targetBook.bookUrl)),
    sourceDao: _FakeSourceDao(),
    contentDao: null,
  );
}

Book _book() {
  return Book(
    bookUrl: 'test://book',
    origin: 'local',
    originName: 'fixture',
    name: '測試書',
  );
}

List<BookChapter> _chapters(String bookUrl) {
  return List<BookChapter>.generate(3, (index) {
    return BookChapter(
      index: index,
      bookUrl: bookUrl,
      title: '第${index + 1}章',
      content: List<String>.filled(
        12,
        '這是第${index + 1}章的測試內容，用於建立足夠多的排版行與頁面。',
      ).join('\n\n'),
    );
  });
}

ReaderV2LayoutSpec _spec({double fontSize = 18}) {
  return ReaderV2LayoutSpec.fromViewport(
    viewportSize: const Size(240, 220),
    style: ReaderV2LayoutStyle(
      fontSize: fontSize,
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

class _CountingLayoutEngine extends ReaderV2LayoutEngine {
  int layoutCount = 0;

  @override
  ReaderV2ChapterLayout layout(
    ReaderV2Content content,
    ReaderV2LayoutSpec spec,
  ) {
    layoutCount += 1;
    return super.layout(content, spec);
  }
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

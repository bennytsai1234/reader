import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';
import 'package:inkpage_reader/features/reader/runtime/read_view_runtime_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBookDao implements BookDao {
  @override
  Future<void> updateProgress(
    String bookUrl,
    int chapterIndex,
    String chapterTitle,
    int pos,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterDao implements ChapterDao {
  @override
  Future<List<BookChapter>> getChapters(String bookUrl) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeReplaceRuleDao implements ReplaceRuleDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookSourceDao implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookmarkDao implements BookmarkDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeReaderProvider extends ReaderProvider {
  bool knownEmpty = false;

  _FakeReaderProvider()
      : super(
          book: Book(bookUrl: 'book', name: 'Book', origin: 'local'),
        );

  @override
  bool isKnownEmptyChapter(int index) => knownEmpty && index == currentChapterIndex;
}

void _setupDi() {
  if (getIt.isRegistered<BookDao>()) getIt.unregister<BookDao>();
  if (getIt.isRegistered<ChapterDao>()) getIt.unregister<ChapterDao>();
  if (getIt.isRegistered<ReplaceRuleDao>()) getIt.unregister<ReplaceRuleDao>();
  if (getIt.isRegistered<BookSourceDao>()) {
    getIt.unregister<BookSourceDao>();
  }
  if (getIt.isRegistered<BookmarkDao>()) getIt.unregister<BookmarkDao>();

  getIt.registerLazySingleton<BookDao>(() => _FakeBookDao());
  getIt.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
  getIt.registerLazySingleton<ReplaceRuleDao>(() => _FakeReplaceRuleDao());
  getIt.registerLazySingleton<BookSourceDao>(() => _FakeBookSourceDao());
  getIt.registerLazySingleton<BookmarkDao>(() => _FakeBookmarkDao());
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _setupDi();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_service.methods'),
      (call) async => null,
    );
  });

  group('ReadViewRuntimeCoordinator', () {
    const coordinator = ReadViewRuntimeCoordinator();

    test('載入中時回傳 loading state', () {
      final provider = _FakeReaderProvider()
        ..lifecycle = ReaderLifecycle.loading
        ..pageTurnMode = PageAnim.slide;

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isTrue);
      expect(state.message, '正在載入內容');
      provider.dispose();
    });

    test('無章節時回傳暫無章節', () {
      final provider = _FakeReaderProvider()
        ..lifecycle = ReaderLifecycle.ready
        ..pageTurnMode = PageAnim.slide
        ..viewSize = const Size(300, 500);

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isFalse);
      expect(state.message, '暫無章節');
      provider.dispose();
    });

    test('已知空章節時回傳本章暫無內容', () {
      final provider = _FakeReaderProvider()
        ..lifecycle = ReaderLifecycle.ready
        ..pageTurnMode = PageAnim.slide
        ..viewSize = const Size(300, 500)
        ..chapters = [
          BookChapter(title: 'c0', index: 0, bookUrl: 'book'),
        ]
        ..knownEmpty = true;

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isFalse);
      expect(state.message, '本章暫無內容');
      provider.dispose();
    });

    test('非 loading 且無可見資料時回傳暫無可顯示頁面', () {
      final provider = _FakeReaderProvider()
        ..lifecycle = ReaderLifecycle.ready
        ..pageTurnMode = PageAnim.scroll
        ..viewSize = const Size(300, 500)
        ..chapters = [
          BookChapter(title: 'c0', index: 0, bookUrl: 'book'),
        ];

      final state = coordinator.resolveViewportState(
        provider,
        hasVisibleData: false,
      );

      expect(state.showLoading, isFalse);
      expect(state.message, '暫無可顯示頁面');
      provider.dispose();
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:legado_reader/features/reader/runtime/reader_navigation_controller.dart';
import 'package:legado_reader/features/reader/runtime/reader_restore_coordinator.dart';
import 'package:legado_reader/features/reader/runtime/reader_scroll_visibility_coordinator.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';

void main() {
  ReaderChapter makeChapter() {
    return ReaderChapter(
      chapter: BookChapter(title: 'chapter', index: 0),
      index: 0,
      title: 'chapter',
      pages: [
        TextPage(
          index: 0,
          title: 'chapter',
          chapterIndex: 0,
          pageSize: 2,
          lines: [
            TextLine(
              text: 'AAAA',
              width: 100,
              height: 20,
              chapterPosition: 0,
              lineTop: 0,
              lineBottom: 20,
              paragraphNum: 1,
            ),
            TextLine(
              text: 'BBBB',
              width: 100,
              height: 20,
              chapterPosition: 4,
              lineTop: 20,
              lineBottom: 40,
              paragraphNum: 1,
              isParagraphEnd: true,
            ),
          ],
        ),
      ],
    );
  }

  group('Reader runtime flow', () {
    test('restore command 會抑制 visible progress 並保留 restore target', () {
      final navigation = ReaderNavigationController();
      final restore = ReaderRestoreCoordinator();

      expect(navigation.beginChapterJump(ReaderCommandReason.restore), isTrue);
      expect(navigation.shouldPersistVisiblePosition(DateTime.now()), isFalse);

      final token = restore.registerPendingScrollRestore(
        chapterIndex: 2,
        localOffset: 88,
      );

      expect(restore.matchesPendingScrollRestore(token), isTrue);
      final target = restore.consumePendingScrollRestore();
      expect(target, isNotNull);
      expect(target!.chapterIndex, 2);
      expect(target.localOffset, 88);
    });

    test('auto page step 與 visible preload 會共享同一個 top chapter', () {
      final navigation = ReaderNavigationController();
      final visibility = ReaderScrollVisibilityCoordinator();
      final chapter = makeChapter();

      final step = navigation.evaluateScrollAutoPageStep(
        isAutoPaging: true,
        isAutoPagePaused: false,
        isLoading: false,
        pageTurnMode: PageAnim.scroll,
        viewSize: const Size(300, 500),
        visibleChapterIndex: 1,
        visibleChapterLocalOffset: 0,
        scrollDeltaPerFrame: (_, __) => 12,
        chapterAt: (_) => chapter,
        pagesForChapter: (_) => chapter.pages,
        dtSeconds: 0.016,
      );
      final update = visibility.evaluate(
        visibleChapterIndexes: const [1, 2],
        currentChapterIndex: 1,
        hasRuntimeChapter: (_) => false,
        isLoadingChapter: (_) => false,
      );

      expect(step, isNotNull);
      expect(step!.chapterIndex, 1);
      expect(update.preloadCenterChapter, 1);
      expect(update.chaptersToEnsure, [1, 2]);
    });
  });
}

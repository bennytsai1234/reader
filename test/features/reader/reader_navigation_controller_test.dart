import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:legado_reader/features/reader/runtime/reader_navigation_controller.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';

void main() {
  ReaderChapter makeChapter() {
    final pages = <TextPage>[
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
          ),
        ],
      ),
    ];
    return ReaderChapter(
      chapter: BookChapter(title: 'chapter', index: 0),
      index: 0,
      title: 'chapter',
      pages: pages,
    );
  }

  group('ReaderNavigationController', () {
    test('程式化 jump 會暫時禁止 visible progress persistence', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.tts), isTrue);
      expect(nav.shouldPersistVisiblePosition(DateTime.now()), isFalse);
    });

    test('page change consume 會回傳最後一次 slide jump reason', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.autoPage), isTrue);
      expect(
        nav.consumePendingSlideJumpReason(),
        ReaderCommandReason.autoPage,
      );
      expect(nav.consumePageChangeReason(), ReaderCommandReason.autoPage);
    });

    test('evaluateScrollAutoPageStep 會回傳 scroll 目標位置', () {
      final nav = ReaderNavigationController();
      final chapter = makeChapter();

      final step = nav.evaluateScrollAutoPageStep(
        isAutoPaging: true,
        isAutoPagePaused: false,
        isLoading: false,
        pageTurnMode: PageAnim.scroll,
        viewSize: const Size(200, 400),
        visibleChapterIndex: 0,
        visibleChapterLocalOffset: 0,
        scrollDeltaPerFrame: (viewSize, dtSeconds) => 10,
        chapterAt: (_) => chapter,
        pagesForChapter: (_) => chapter.pages,
        dtSeconds: 0.016,
      );

      expect(step, isNotNull);
      expect(step!.advanceChapter, isFalse);
      expect(step.chapterIndex, 0);
      expect(step.localOffset, 10);
    });

    test('較高優先級 user 命令可以覆蓋較低優先級 autoPage', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.autoPage), isTrue);
      expect(nav.beginChapterJump(ReaderCommandReason.user), isTrue);
      expect(nav.activeCommandReason, ReaderCommandReason.user);
    });

    test('userScroll 可以打斷 tts command', () {
      final nav = ReaderNavigationController();

      expect(nav.beginChapterJump(ReaderCommandReason.tts), isTrue);
      expect(nav.beginChapterJump(ReaderCommandReason.userScroll), isTrue);
      expect(nav.activeCommandReason, ReaderCommandReason.userScroll);
    });

    test('restore 期間的 page change reason 不會被誤判成可持久化進度', () {
      final nav = ReaderNavigationController();

      expect(nav.beginSlideJump(ReaderCommandReason.restore), isTrue);
      final jumpReason = nav.consumePendingSlideJumpReason();
      final pageChangeReason = nav.consumePageChangeReason();

      expect(jumpReason, ReaderCommandReason.restore);
      expect(pageChangeReason, ReaderCommandReason.restore);
      expect(nav.shouldPersistForReason(pageChangeReason), isFalse);
      expect(nav.shouldPersistVisiblePosition(DateTime.now()), isFalse);
    });
  });
}

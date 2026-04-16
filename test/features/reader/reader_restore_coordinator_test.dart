import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_restore_coordinator.dart';

void main() {
  group('ReaderRestoreCoordinator', () {
    test('register 會遞增 token 並保存 restore target', () {
      final coordinator = ReaderRestoreCoordinator();

      final first = coordinator.registerPendingScrollRestore(
        chapterIndex: 2,
        localOffset: 128,
      );
      final second = coordinator.registerPendingScrollRestore(
        chapterIndex: 3,
        localOffset: 256,
      );

      expect(first, 1);
      expect(second, 2);
      expect(coordinator.matchesPendingScrollRestore(2), isTrue);
      expect(coordinator.pendingScrollRestoreChapterIndex, 3);
      expect(coordinator.pendingScrollRestoreLocalOffset, 256);
    });

    test('clear 會清空 target 但保留 token 序列', () {
      final coordinator = ReaderRestoreCoordinator();

      coordinator.registerPendingScrollRestore(
        chapterIndex: 1,
        localOffset: 64,
      );
      coordinator.clear();

      expect(coordinator.consumePendingScrollRestore(), isNull);
      expect(coordinator.pendingScrollRestoreToken, 1);
    });
  });
}

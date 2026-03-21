import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

typedef PendingScrollAction =
    ({
      int chapterIndex,
      double localOffset,
      int token,
      bool isRestore,
    });

class ReadViewRuntimeCoordinator {
  const ReadViewRuntimeCoordinator();

  bool shouldRunScrollAutoPage(ReaderProvider provider) {
    return provider.pageTurnMode == PageAnim.scroll &&
        provider.isAutoPaging &&
        !provider.isAutoPagePaused;
  }

  PendingScrollAction? consumePendingScrollAction(ReaderProvider provider) {
    if (provider.pageTurnMode != PageAnim.scroll) return null;

    final pendingChapterJump = provider.consumePendingChapterJump();
    if (pendingChapterJump != null) {
      if (provider.isRestoring) {
        final token = provider.registerPendingScrollRestore(
          chapterIndex: pendingChapterJump.chapterIndex,
          localOffset: pendingChapterJump.localOffset,
        );
        return (
          chapterIndex: pendingChapterJump.chapterIndex,
          localOffset: pendingChapterJump.localOffset,
          token: token,
          isRestore: true,
        );
      }
      return (
        chapterIndex: pendingChapterJump.chapterIndex,
        localOffset: pendingChapterJump.localOffset,
        token: -1,
        isRestore: false,
      );
    }

    if (!provider.isRestoring) return null;
    final pendingRestore = provider.consumePendingScrollRestore();
    if (pendingRestore == null) return null;
    return (
      chapterIndex: pendingRestore.chapterIndex,
      localOffset: pendingRestore.localOffset,
      token: provider.pendingScrollRestoreToken,
      isRestore: true,
    );
  }

  bool shouldFollowTts(
    ReaderProvider provider, {
    required int lastTtsScrolledStart,
    required bool isUserScrolling,
  }) {
    return provider.pageTurnMode == PageAnim.scroll &&
        provider.ttsStart >= 0 &&
        provider.ttsStart != lastTtsScrolledStart &&
        !isUserScrolling;
  }

  bool shouldWaitForFirstContent(
    ReaderProvider provider, {
    required bool hasVisibleData,
  }) {
    return !hasVisibleData &&
        (provider.lifecycle == ReaderLifecycle.loading ||
            provider.lifecycle == ReaderLifecycle.restoring ||
            provider.viewSize == null ||
            provider.chapters.isNotEmpty);
  }

  bool shouldHoldScrollUntilRestored(
    ReaderProvider provider, {
    required bool hasVisibleData,
  }) {
    return provider.pageTurnMode == PageAnim.scroll &&
        provider.lifecycle == ReaderLifecycle.restoring &&
        hasVisibleData;
  }

  bool shouldRestoreSlidePage(ReaderProvider provider) {
    return provider.isRestoring && provider.pageTurnMode != PageAnim.scroll;
  }
}

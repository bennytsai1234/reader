import 'package:flutter/widgets.dart';

/// Encapsulates PageView jump logic with deduplication and debouncing.
///
/// Replaces the manual `_deferredPendingJump` + `_schedulePendingJump()`
/// pattern previously in [ReaderPage].
class SlidePageController {
  final PageController pageController;
  int? _pendingJump;
  bool _scheduled = false;
  bool _disposed = false;

  SlidePageController(this.pageController);

  /// Schedule a jump to [pageIndex]. Multiple calls before the next frame
  /// coalesce — only the last target is used.
  void jumpTo(
    int pageIndex, {
    VoidCallback? onWillJump,
  }) {
    _pendingJump = pageIndex;
    if (_scheduled || _disposed) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final target = _pendingJump;
      _pendingJump = null;
      if (_disposed || target == null || !pageController.hasClients) return;
      if (pageController.position.isScrollingNotifier.value) {
        // User is actively scrolling — retry next frame
        jumpTo(target);
        return;
      }
      if (pageController.page?.round() != target) {
        onWillJump?.call();
        pageController.jumpToPage(target);
      }
    });
  }

  void dispose() {
    _disposed = true;
    _pendingJump = null;
  }
}

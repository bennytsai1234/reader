# Reader Lifecycle & Core Reading Refactor Design

## Overview

Full refactoring of the reader module's lifecycle management, slide mode window model, scroll mode preloading, and UI layer. Targets three user-facing bugs:

1. **Initialization jitter** (~0.5s visual shaking when opening a book)
2. **Slide mode chapter jump bug** (ch12 last page → briefly shows ch14 → corrects to ch13)
3. **Scroll mode boundary stutter** (~0.1s loading placeholder flash at chapter boundaries)

## Scope

- `ReadBookController` lifecycle rewrite
- `ReaderContentMixin` slide window model replacement
- `ReaderContentMixin` scroll preload strategy
- `ReadViewRuntime` state observation refactor
- `ReaderPage` slide controller encapsulation
- `ScrollModeDelegate` placeholder and sync-paginate improvements

## Non-Goals

- TTS logic refactor (preserved as-is)
- BookSource / network layer changes
- Database schema changes
- Auto-page logic changes (preserved as-is)

---

## 1. Lifecycle Refactor (Initialization Jitter Fix)

### Problem

`_init()` triggers 5+ sequential `notifyListeners()` calls during startup:
1. Settings loaded → notify
2. `setViewSize()` → `doPaginate()` clears all caches → notify
3. Chapter content loaded → notify
4. `applyPendingRestore()` jumps position → notify
5. `completeRestoreTransition()` → lifecycle = ready → notify

Each rebuild causes visible frame jitter.

### Design

Replace the current fire-and-notify pattern with a **three-phase pipeline** where only the phase 2→3 transition triggers a UI rebuild.

#### Phase 1: PREPARE (no UI updates)

All async data loading runs in parallel, results stored but not applied to UI state:

```dart
Future<void> _init() async {
  // Phase 1: parallel data loading, zero notifyListeners
  final results = await Future.wait([
    _loadSettings(),      // returns settings map
    _loadChapters(),      // returns List<BookChapter>
    _loadSource(),        // returns BookSource?
    _loadReadAloudPreferences(),
  ]);

  // Store results without notifying
  _applySettingsSilent(results[0]);
  _applyChaptersSilent(results[1]);
  _applySourceSilent(results[2]);

  // Phase 2: wait for viewSize, then render
  await _awaitViewSizeAndRender();
}
```

#### Phase 2: RENDER (single UI update)

Wait for `viewSize` from LayoutBuilder, then do all pagination + position restore in one batch:

```dart
Future<void> _awaitViewSizeAndRender() async {
  final size = await _viewSizeCompleter.future;

  // All state mutations in one batch — no intermediate notifyListeners
  updatePaginationConfig();

  final pages = await _loadInitialChapter();
  final restoreTarget = _calculateRestorePosition(pages);

  // Single atomic state update
  _batchUpdate(() {
    viewSize = size;
    chapterPagesCache[currentChapterIndex] = pages;
    currentPageIndex = restoreTarget.pageIndex;
    // ... all other state
    lifecycle = ReaderLifecycle.ready;
  });
  // ↑ triggers exactly ONE notifyListeners()

  // Phase 3: background warmup
  unawaited(_warmupBackground());
}
```

#### Phase 3: WARMUP (background, non-blocking)

```dart
Future<void> _warmupBackground() async {
  _startHeartbeat();
  _preloadAdjacentChapters();
  _initTtsIfNeeded();
}
```

#### New helper: `_batchUpdate()`

```dart
bool _isBatching = false;
bool _batchDirty = false;

void _batchUpdate(VoidCallback fn) {
  _isBatching = true;
  _batchDirty = false;
  try {
    fn();
  } finally {
    _isBatching = false;
    if (_batchDirty) {
      notifyListeners();
    }
  }
}

// Override in base:
@override
void notifyListeners() {
  if (_isBatching) {
    _batchDirty = true;
    return;
  }
  super.notifyListeners();
}
```

#### ViewSize handling during init

Replace the current `setViewSize()` → immediate paginate pattern:

```dart
final Completer<Size> _viewSizeCompleter = Completer<Size>();

void setViewSize(Size size) {
  if (!_viewSizeCompleter.isCompleted) {
    _viewSizeCompleter.complete(size);
    return; // Don't paginate during init — Phase 2 handles it
  }
  // Post-init: existing logic for orientation changes etc.
  _handleViewSizeChange(size);
}
```

#### Remove `ReaderLifecycle.restoring`

The `restoring` state is no longer needed because position restore happens before the first render. Lifecycle simplifies to:

```dart
enum ReaderLifecycle { loading, ready, disposed }
```

`completeRestoreTransition()` is removed entirely. `isRestoring` checks throughout the codebase are removed.

### UI-side: Init overlay

`ReadViewRuntime` shows a theme-colored placeholder during `lifecycle == loading`, then fades in content:

```dart
Widget build(BuildContext context) {
  if (provider.lifecycle == ReaderLifecycle.loading) {
    return Container(color: currentTheme.backgroundColor);
  }
  return FadeTransition(
    opacity: _fadeAnimation, // 150ms ease-in
    child: _buildContent(),
  );
}
```

The fade animation triggers once when lifecycle transitions to `ready`.

---

## 2. Slide Window Model Refactor (Chapter Jump Bug Fix)

### Problem

`onPageChanged()` updates `currentChapterIndex` BEFORE rebuilding `slidePages`. The new merge (prev+current+next) uses the updated index, producing a window that includes the WRONG next chapter. For one frame, the PageView displays content from that wrong chapter before `requestJumpToPage()` corrects it.

### Design: Segmented Slide Window

Replace the flat `List<TextPage> slidePages` with a structured window:

```dart
class SlideWindow {
  final List<SlideSegment> segments;

  SlideWindow(this.segments);

  int get totalPages => segments.fold(0, (sum, s) => sum + s.pages.length);

  List<TextPage> get flatPages => segments.expand((s) => s.pages).toList();

  /// Find which segment and local index a global index maps to
  ({int segmentIdx, int localIdx, int chapterIndex}) resolve(int globalIndex) {
    int offset = 0;
    for (int i = 0; i < segments.length; i++) {
      if (globalIndex < offset + segments[i].pages.length) {
        return (
          segmentIdx: i,
          localIdx: globalIndex - offset,
          chapterIndex: segments[i].chapterIndex,
        );
      }
      offset += segments[i].pages.length;
    }
    // clamp to last
    final last = segments.last;
    return (
      segmentIdx: segments.length - 1,
      localIdx: last.pages.length - 1,
      chapterIndex: last.chapterIndex,
    );
  }

  /// Map from (chapterIndex, localPageIndex) to global index
  int toGlobal(int chapterIndex, int localPageIndex) {
    int offset = 0;
    for (final seg in segments) {
      if (seg.chapterIndex == chapterIndex) {
        return offset + localPageIndex;
      }
      offset += seg.pages.length;
    }
    return -1;
  }

  /// Recenter the window around a new chapter without changing what's visible
  /// Returns the new global index for the same page the user was viewing
  ({SlideWindow window, int mappedIndex}) recenter({
    required int viewingChapterIndex,
    required int viewingLocalPageIndex,
    required Map<int, List<TextPage>> cache,
    required int totalChapters,
  }) {
    final prevIdx = viewingChapterIndex - 1;
    final nextIdx = viewingChapterIndex + 1;

    final newSegments = <SlideSegment>[
      if (prevIdx >= 0 && cache.containsKey(prevIdx))
        SlideSegment(chapterIndex: prevIdx, pages: cache[prevIdx]!),
      SlideSegment(chapterIndex: viewingChapterIndex, pages: cache[viewingChapterIndex] ?? []),
      if (nextIdx < totalChapters && cache.containsKey(nextIdx))
        SlideSegment(chapterIndex: nextIdx, pages: cache[nextIdx]!),
    ];

    final newWindow = SlideWindow(newSegments);
    final mappedIndex = newWindow.toGlobal(viewingChapterIndex, viewingLocalPageIndex);

    return (window: newWindow, mappedIndex: mappedIndex);
  }
}

class SlideSegment {
  final int chapterIndex;
  final List<TextPage> pages;

  const SlideSegment({required this.chapterIndex, required this.pages});
}
```

### Recentering strategy

The window recenters **only when the user fully enters a new chapter** (not on the boundary page):

```dart
void onPageChanged(int globalIndex) {
  final resolved = _slideWindow.resolve(globalIndex);
  final newChapterIndex = resolved.chapterIndex;

  // Update page index and visible chapter — no window rebuild yet
  currentPageIndex = globalIndex;
  visibleChapterIndex = newChapterIndex;

  // Only recenter if the CENTER segment has changed
  final centerChapter = _slideWindow.segments
      .firstWhere((s) => s.chapterIndex == currentChapterIndex);

  if (newChapterIndex != currentChapterIndex) {
    currentChapterIndex = newChapterIndex;

    // Recenter: atomic swap of window + index
    final result = _slideWindow.recenter(
      viewingChapterIndex: newChapterIndex,
      viewingLocalPageIndex: resolved.localIdx,
      cache: chapterPagesCache,
      totalChapters: chapters.length,
    );

    _slideWindow = result.window;
    slidePages = result.window.flatPages; // for backward compat
    currentPageIndex = result.mappedIndex;

    // Jump to corrected index in same frame
    requestJumpToPage(result.mappedIndex, reason: ReaderCommandReason.system);

    // Preload the new neighbor
    _preloadSlideNeighbors(newChapterIndex);
  }

  notifyListeners();
}
```

### Remove `(this as dynamic)` hacks

Define callbacks via constructor injection in `ReaderContentMixin`:

```dart
// In ReadBookController constructor or _init():
_contentCallbacks = ContentCallbacks(
  buildSlideRuntimePages: buildSlideRuntimePages,
  refreshChapterRuntime: refreshChapterRuntime,
);
```

`ReaderContentMixin` uses `_contentCallbacks.buildSlideRuntimePages?.call()` instead of `(this as dynamic).buildSlideRuntimePages?.call()`.

---

## 3. Scroll Mode Predictive Preload (Boundary Stutter Fix)

### Problem

Preload triggers AFTER crossing a chapter boundary (`updateScrollPreloadForVisibleChapter` uses `unawaited`). `ScrollablePositionedList` immediately renders → shows placeholder → 100ms later content arrives.

### Design

#### 3a. Predictive preload based on scroll position

Monitor scroll position within the current chapter. When user is in the last/first 20% of a chapter, start loading the next/prev chapter:

```dart
void _handleScrollPositionUpdate(int visibleChapter, double localOffset, double alignment) {
  final pages = chapterPagesCache[visibleChapter];
  if (pages == null || pages.isEmpty) return;

  final chapterHeight = ChapterPositionResolver.chapterHeight(pages);
  final progress = localOffset / chapterHeight;

  // Approaching end → preload next
  if (progress > 0.8) {
    final nextIdx = visibleChapter + 1;
    if (nextIdx < chapters.length && !chapterPagesCache.containsKey(nextIdx)) {
      ensureChapterCached(nextIdx, silent: true, prioritize: true);
    }
  }

  // Approaching start → preload prev
  if (progress < 0.2) {
    final prevIdx = visibleChapter - 1;
    if (prevIdx >= 0 && !chapterPagesCache.containsKey(prevIdx)) {
      ensureChapterCached(prevIdx, silent: true, prioritize: true);
    }
  }
}
```

This is called from `handleVisibleScrollState()` which already receives `localOffset` and `alignment`.

#### 3b. Synchronous pagination for local books

For local books, content is already in memory (or reads from disk in <5ms). Skip the async path and paginate synchronously in the builder:

```dart
// In ScrollModeDelegate.build(), when building a chapter item:
Widget _buildChapterItem(int chapterIndex) {
  var pages = provider.chapterPagesCache[chapterIndex];

  // Sync fast-path for local books with cached content
  if ((pages == null || pages.isEmpty) && provider.isLocalBook) {
    pages = provider.trySyncPaginate(chapterIndex);
  }

  if (pages == null || pages.isEmpty) {
    return _buildPlaceholder(chapterIndex);
  }

  return _buildChapterContent(pages);
}
```

`trySyncPaginate()` checks if raw content is in `ChapterContentManager._contentCache`. If yes, paginates synchronously and returns pages. If not, returns null (falls through to placeholder + async load).

```dart
// In ReaderContentMixin:
List<TextPage>? trySyncPaginate(int chapterIndex) {
  if (!hasContentManager) return null;
  final content = contentManager.getCachedContent(chapterIndex);
  if (content == null) return null;

  final pages = contentManager.paginateSync(chapterIndex, content);
  if (pages.isNotEmpty) {
    chapterPagesCache[chapterIndex] = pages;
    refreshChapterRuntime(chapterIndex);
  }
  return pages.isEmpty ? null : pages;
}
```

#### 3c. Placeholder height estimation

Replace fixed-height placeholder with estimated height based on neighbor chapters:

```dart
Widget _buildPlaceholder(int chapterIndex) {
  // Estimate height from adjacent cached chapters
  final estimatedHeight = _estimateChapterHeight(chapterIndex);

  return SizedBox(
    height: estimatedHeight,
    child: Center(
      child: SizedBox(
        width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

double _estimateChapterHeight(int chapterIndex) {
  // Use average of cached neighbor heights
  final heights = <double>[];
  for (final offset in [-1, 1]) {
    final neighbor = chapterIndex + offset;
    final pages = provider.chapterPagesCache[neighbor];
    if (pages != null && pages.isNotEmpty) {
      heights.add(ChapterPositionResolver.chapterHeight(pages));
    }
  }
  if (heights.isEmpty) return provider.viewSize?.height ?? 600;
  return heights.reduce((a, b) => a + b) / heights.length;
}
```

---

## 4. UI Layer Refactor

### 4a. ReadViewRuntime state observation

Extract a `ReadViewRuntimeCoordinator` that consolidates all provider-to-UI event handling:

Current pattern (scattered):
```dart
void _onProviderStateChanged() {
  // 15+ conditional checks mixed together
  setState(() {});
}
```

New pattern:
```dart
class ReadViewRuntimeCoordinator {
  void onProviderChanged(ReaderProvider provider, _ReadViewRuntimeState state) {
    _handlePendingJumps(provider, state);
    _handleTtsFollow(provider, state);
    _handleAutoPage(provider, state);
    _syncScrollDriver(provider, state);
  }
}
```

Note: `ReadViewRuntimeCoordinator` may already partially exist in the codebase. The refactor extends it to cover ALL event routing, removing ad-hoc logic from `_onProviderStateChanged()`.

### 4b. SlidePageController wrapper

Encapsulate PageView jump logic (currently in `ReaderPage._schedulePendingJump()`):

```dart
class SlidePageController {
  final PageController _pageCtrl;
  int? _pendingJump;
  bool _scheduled = false;

  SlidePageController(this._pageCtrl);

  void jumpTo(int pageIndex) {
    _pendingJump = pageIndex;
    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        final target = _pendingJump;
        _pendingJump = null;
        if (target != null && _pageCtrl.hasClients) {
          if (!_pageCtrl.position.isScrollingNotifier.value) {
            _pageCtrl.jumpToPage(target);
          }
        }
      });
    }
  }

  void dispose() {
    _pageCtrl.dispose();
  }
}
```

This replaces `_deferredPendingJump` and `_schedulePendingJump()` in `ReaderPage`.

### 4c. ScrollModeDelegate rendering

- Use `trySyncPaginate()` fast-path as described in section 3b
- Estimated placeholder heights as described in section 3c
- No other structural changes to `ScrollablePositionedList` usage

---

## 5. Migration Strategy

Since the user accepts a non-incremental approach:

1. All changes happen on a feature branch
2. Order of implementation:
   - `_batchUpdate()` and `notifyListeners` override in base
   - `SlideWindow` / `SlideSegment` data structures
   - `_init()` rewrite with three-phase pipeline
   - `onPageChanged()` rewrite with `SlideWindow.resolve()`
   - Predictive scroll preload + `trySyncPaginate()`
   - `ReadViewRuntime` coordinator consolidation
   - `SlidePageController` extraction
   - Init overlay + fade transition
   - Remove `ReaderLifecycle.restoring` and all `isRestoring` checks
   - Remove `(this as dynamic)` casts
3. Manual testing checklist after implementation:
   - Open a local book → no jitter, smooth fade-in
   - Open a remote book → no jitter, placeholder then fade
   - Slide mode: ch12 last page → slide right → ch13 first page (no ch14 flash)
   - Slide mode: rapid chapter switching (prev/next taps)
   - Scroll mode: continuous scroll across 3+ chapter boundaries → no placeholder flash
   - Scroll mode: scroll backward across boundary
   - TTS playback across chapter boundary
   - Auto-page across chapter boundary
   - Change font size mid-read → repaginate → correct position
   - Orientation change → correct re-layout
   - App background → foreground → correct state

---

## Files Modified

| File | Change Type |
|------|------------|
| `reader_provider_base.dart` | Major: add `_batchUpdate`, override `notifyListeners`, simplify lifecycle enum |
| `reader_content_mixin.dart` | Major: replace flat slidePages with `SlideWindow`, rewrite `onPageChanged`, add predictive preload, add `trySyncPaginate()` |
| `read_book_controller.dart` | Major: rewrite `_init()` as three-phase pipeline, remove `restoring` logic, inject content callbacks |
| `reader_progress_mixin.dart` | Medium: remove `applyPendingRestore()` (merged into phase 2), simplify restore logic |
| `reader_page.dart` | Medium: replace manual jump logic with `SlidePageController` |
| `read_view_runtime.dart` | Medium: add init overlay + fade, consolidate `_onProviderStateChanged` into coordinator |
| `scroll_mode_delegate.dart` | Medium: add sync-paginate fast path, estimated placeholder heights |
| `chapter_content_manager.dart` | Small: expose `getCachedContent()`, add `paginateSync()` |
| `reader_settings_mixin.dart` | Small: no structural change, settings apply silently during init |
| `reader_auto_page_mixin.dart` | No change |
| `reader_tts_mixin.dart` | Small: remove `isRestoring` checks |

## New Files

| File | Purpose |
|------|---------|
| `slide_window.dart` | `SlideWindow` + `SlideSegment` data structures |
| `slide_page_controller.dart` | `SlidePageController` wrapper for PageView jumps |
| `content_callbacks.dart` | `ContentCallbacks` class replacing `(this as dynamic)` casts |

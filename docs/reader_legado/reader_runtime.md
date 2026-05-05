# Reader Runtime

## Current Responsibility

- Owns `lib/features/reader_v2`, the user-visible reading runtime: opening books, resolving chapters, loading and transforming content, layout, rendering, scroll/slide viewport behavior, progress save/restore, preload, TTS, auto page, bookmark, in-reader settings, and in-reader replace-rule UI.
- Future work should start here when a symptom appears in the reading screen, chapter navigation, position restoration, layout, viewport gesture behavior, TTS following, auto page, or in-reader controls.

## Scope

- Shell/application: `lib/features/reader_v2/shell/`, `application/`.
- Content: `content/reader_v2_chapter_repository.dart`, `reader_v2_content_transformer.dart`.
- Runtime state: `runtime/reader_v2_runtime.dart`, `reader_v2_resolver.dart`, `reader_v2_preload_scheduler.dart`, `reader_v2_progress_controller.dart`, state/location/page-window models.
- Layout/render/viewport: `layout/`, `render/`, `viewport/`.
- Feature controllers: `features/menu/`, `features/settings/`, `features/tts/`, `features/auto_page/`, `features/bookmark/`, `features/replace_rule/`.
- Tests: `test/features/reader_v2/`.

## Dependencies And Impact

- Depends on `Book`, `BookChapter`, DAOs, `BookSourceService`, `ReaderChapterContentStore`, `ReaderChapterContentStorage`, replace rules, Chinese conversion, `SettingsProvider`, and reader-v2 prefs repository.
- Impacts persisted progress fields, Bookshelf ordering/display, Book Detail open/read state, Settings/Cache preferences, TTS service state, bookmarks, and content cache.
- Layout signature, content transformation, and progress anchor changes can affect a user's ability to return to the same reading position.

## Key Flows

- Reader shell constructs dependencies and coordinates page lifecycle through application coordinators and `ReaderV2SessionFacade`.
- `ReaderV2Runtime.openBook()` resolves book/chapter state, loads current content, lays out pages, and prepares adjacent chapter windows.
- `ReaderV2ChapterRepository` loads online/local content, applies cache, replace rules, and Chinese text conversion.
- `ReaderV2LayoutEngine` produces line boxes and render pages from layout spec and style.
- Viewport controllers capture visible position, restore anchors, and handle scroll or slide interaction.
- Progress controller persists chapter index, char offset, visual offset, and optional anchor JSON back to `Book`.

## Change Entry Points

- Open/jump/preload: `runtime/reader_v2_runtime.dart`, `reader_v2_resolver.dart`, `reader_v2_preload_scheduler.dart`.
- Progress: `runtime/reader_v2_progress_controller.dart`, `reader_v2_location.dart`, persisted book fields.
- Content transformation: `content/reader_v2_chapter_repository.dart`, `reader_v2_content_transformer.dart`, `lib/core/engine/reader/`.
- Layout: `layout/reader_v2_layout_engine.dart`, `reader_v2_layout_spec.dart`, `reader_v2_style.dart`.
- Rendering and viewport: `render/`, `viewport/scroll_reader_v2_viewport.dart`, `slide_reader_v2_viewport.dart`, position tracker/calculator.
- In-reader features: `features/tts/`, `features/settings/`, `features/auto_page/`, `features/bookmark/`, `features/replace_rule/`.
- Tests: `flutter test test/features/reader_v2`.

## Change Routes

- Open-book or chapter switch change: start in runtime/resolver, keep request-id and generation guards, then verify preload, error phase, and progress save behavior.
- Content pipeline change: update repository/transformer, then check replace rules, Chinese conversion, cache invalidation, local-book fallback, and content tests.
- Layout change: update layout spec/engine, then verify render pages, TTS character ranges, viewport restoration, and layout tests.
- Scroll/slide interaction change: update viewport controller/tracker/calculator, then run viewport and stress tests plus runtime tests.
- TTS or auto-page change: inspect controller, viewport scrolling/highlight, global `TTSService`, and settings integration.
- If runtime API, state lifecycle, or persisted progress changes, update Data Model, Book Detail, Bookshelf, and Settings/Cache docs where needed.

## Known Risks

- Runtime uses request IDs, layout generation, and capture/restore callbacks to prevent stale async work; new async paths must preserve those guards.
- Content cache generation must be cleared on reload, replace-rule, Chinese conversion, or source switch changes.
- Progress includes chapter index, char offset, visual offset, and anchor JSON; layout/viewport changes can regress restoration without obvious compile failures.
- TTS highlight depends on line boxes and character ranges.
- Slide neighbor placeholders and preload failures are boundary-sensitive and need more than a single open-page test.

## Reference Notes

- Useful Legado counterparts: `ui/book/read`, `model/ReadBook.kt`, `model/ReadAloud.kt`, `constant/PageAnim.kt`, `help/book/ContentProcessor.kt`.
- Legado is useful for responsibility separation between read shell, state core, layout/page behavior, read-aloud, settings, and content processing. Do not copy Android view/page implementations into Flutter.

## Do Not Do

- Do not put source management, detail-page UI, or settings CRUD directly in runtime core.
- Do not bypass persisted progress contracts in `Book`.
- Do not collapse `application/content/layout/render/runtime/viewport` boundaries for a local fix.

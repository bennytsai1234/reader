# Book Detail

## Current Responsibility

- Owns the detail screen boundary between search/explore/bookshelf and reader runtime: book info, TOC, add/remove bookshelf, change source, change cover, single-book cache status, update checks, and download scheduling entrypoints.
- Future work should start here when data is correct before detail but wrong after detail load, or when source switching, TOC, cover, cache status, or opening reader is inconsistent.

## Scope

- Provider and UI: `lib/features/book_detail/book_detail_provider.dart`, `book_detail_page.dart`, `widgets/`.
- Source switching: `lib/features/book_detail/source/book_detail_change_source_provider.dart`, `widgets/change_source_sheet.dart`, `widgets/book_detail_change_source_item.dart`.
- Cover changes: `lib/features/book_detail/change_cover_provider.dart`, `change_cover_sheet.dart`, `widgets/cover/`.
- Services/data: `BookSourceService`, `BookCoverStorageService`, `DownloadService`, `ReaderChapterContentStore`, `BookDao`, `ChapterDao`, `BookSourceDao`, `ReaderChapterContentDao`.
- Tests: `test/features/book_detail/` and related service tests for cache/download behavior.

## Dependencies And Impact

- Depends on book/search result models, source rules, chapter metadata, content storage, cover storage, download scheduling, reader runtime health, and bookshelf state.
- Impacts Reader Runtime open-book behavior, Bookshelf state/progress, Settings/Cache download/cache UI, Source Manager health, and backup data correctness.
- Detail is a key preservation boundary: source updates and source switches must not lose user-owned progress, bookshelf membership, custom cover, custom intro, or local state.

## Key Flows

- `BookDetailProvider` initializes existing book/source state, loads book info, chapters, cover assets, and cache status.
- Add/remove bookshelf writes book state and triggers bookshelf refresh through shared events/services.
- Source switching loads candidate source info and chapters, then migrates the old book state onto the new source data.
- Cache/download actions ensure chapter metadata exists before scheduling tasks through `DownloadService`.
- Cover selection updates local or remote cover state through cover storage and detail provider state.

## Change Entry Points

- Detail state loading: `book_detail_provider.dart`, especially initialization, source load, book info load, and chapter load paths.
- Detail UI: `book_detail_page.dart`, `widgets/book_info_header.dart`, `book_info_toc_bar.dart`, `book_info_intro.dart`.
- Source switch: `source/book_detail_change_source_provider.dart`, `widgets/change_source_sheet.dart`.
- Cover change: `change_cover_provider.dart`, `change_cover_sheet.dart`, `widgets/cover/`.
- Cache/download: detail provider cache status helpers, `DownloadService`, `ReaderChapterContentStore`.
- Tests: `flutter test test/features/book_detail`.

## Change Routes

- Change detail loading: update provider loading/error state first, then verify source health messages, chapter fallback, and UI compile tests.
- Change source switching: update candidate search and migration, then check `Book.migrateTo`, chapter cleanup, content cache invalidation, progress preservation, and bookshelf refresh.
- Change cache/download entrypoints: synchronize detail cache status, download scheduler, reader content store, and Settings/Cache download manager.
- Change covers: update `ChangeCoverProvider` and cover storage, then verify detail, bookshelf, backup, and local asset handling.
- If detail contracts change, update Reader Runtime, Bookshelf, Data Model, or Settings/Cache docs where downstream assumptions changed.

## Known Risks

- Source switch can silently lose progress, bookshelf state, or custom metadata if migration fields drift.
- Cache status counts ready entries with matching origin; key or origin changes affect detail, download, and reader runtime.
- Download scheduling depends on complete and current chapter metadata.
- Debounced TOC search and async provider work must avoid `notifyListeners()` after dispose.

## Reference Notes

- Useful Legado counterparts: `ui/book/info`, `ui/book/toc`, `ui/book/changesource`, `ui/book/changecover`.
- Legado is useful for preserving user book state while replacing source-derived data. It is not a reason to add unrequested detail subflows.

## Do Not Do

- Do not turn detail into source management or reader settings.
- Do not parse source rules directly in the detail layer; use `BookSourceService` and engine services.
- Do not add missing Legado detail features unless a later task explicitly asks for parity.

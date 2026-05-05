# Bookshelf

## Current Responsibility

- Owns the main bookshelf list, bookshelf sorting, manual reorder, batch selection, local book import entrypoints, book update checks, batch download scheduling, and deletion cleanup entrypoints.
- Future work should start here when a user action begins from the bookshelf or when bookshelf state disagrees with detail, reader progress, download state, or local-book imports.

## Scope

- UI and provider: `lib/features/bookshelf/bookshelf_page.dart`, `bookshelf_provider.dart`, `provider/bookshelf_provider_base.dart`, `bookshelf_logic_mixin.dart`, `bookshelf_update_mixin.dart`, `bookshelf_import_mixin.dart`.
- Supporting services: `lib/core/services/book_storage_service.dart`, `bookshelf_exchange_service.dart`, `bookshelf_state_tracker.dart`, `local_book_service.dart`, `download_service.dart`.
- Data contracts: `BookDao`, `ChapterDao`, `BookSourceDao`, `Book`, `BookChapter`, `ReaderChapterContentStore`.
- Tests: `test/features/bookshelf/`, `test/core/services/bookshelf_exchange_service_test.dart`, local-book import tests when import paths change.

## Dependencies And Impact

- Depends on DAO access, `BookSourceService`, local book parsers, cover storage, reader content storage, download scheduler, and app event bus refresh signals.
- Impacts Book Detail, Reader Runtime opening/progress, Settings/Cache download state, local book storage, backup/restore, and search/detail bookshelf markers.
- Online books and local books split on `Book.isLocal` and `origin == 'local'`; changes must preserve both paths.

## Key Flows

- `BookshelfProvider` composes base state with logic, update, and import mixins.
- `loadBooks()` reads `BookDao.getInBookshelf()`, applies sort/display preferences, and notifies the UI.
- Update checks call source services to refresh book info and chapters without losing user-owned progress and bookshelf metadata.
- Local imports delegate file parsing and chapter generation to `LocalBookService`, then refresh the bookshelf.
- Deletion routes through `BookStorageService.discardBook()` so chapters, content cache, bookmarks, download tasks, and cover assets are cleaned together.

## Change Entry Points

- List state, selection, sorting: `provider/bookshelf_logic_mixin.dart`, `bookshelf_provider_base.dart`, `bookshelf_page.dart`.
- Update and batch download: `provider/bookshelf_update_mixin.dart`, `lib/core/services/download_service.dart`.
- Local import: `provider/bookshelf_import_mixin.dart`, `lib/core/services/local_book_service.dart`, `lib/core/local_book/`.
- Cleanup: `lib/core/services/book_storage_service.dart`.
- Tests: `flutter test test/features/bookshelf test/core/services/bookshelf_exchange_service_test.dart`.

## Change Routes

- Sorting or selection change: update provider state first, then UI rendering and tests that assert visible order or selection mode.
- Book update change: inspect update mixin, `Book.migrateTo`/book preservation logic, chapter insertion, reader progress fields, and detail refresh behavior.
- Local import change: update parser/service boundary, then verify chapter offsets, cover handling, `Book.isLocal`, and reader fallback.
- Delete/cleanup change: keep `BookStorageService.discardBook()` as the central route and validate all downstream storage cleanup.
- If bookshelf state ownership changes, update this module plus Book Detail, Reader Runtime, Settings/Cache, or Data Model docs as needed.

## Known Risks

- Sorting preferences, manual order, and database `order` can drift if only UI state is updated.
- Batch updates must isolate per-book failures; one slow or broken source should not abort the whole bookshelf refresh.
- Download filtering depends on chapter index, book URL, origin, and content-store keys.
- Local TXT import depends on charset and byte offsets; parser changes can break previously imported chapter positions.

## Reference Notes

- Useful Legado counterparts: `ui/main/bookshelf`, `ui/book/manage`, `ui/book/group`, and `help/book/BookHelp.kt`.
- Legado is useful for separating list refresh, grouping/sorting, batch operations, and centralized book cleanup. Feature parity is disabled, so additional Legado bookshelf management abilities are not implied work.

## Do Not Do

- Do not parse book-source rules directly in the bookshelf layer.
- Do not move reader progress-save logic into bookshelf provider.
- Do not add Legado-only bookshelf grouping or batch features unless a later request explicitly asks for them.

# Data Model And Persistence

## Current Responsibility

- Owns the long-lived data contracts for books, chapters, sources, search records, cache records, settings-adjacent models, Drift tables, DAO registration, generated database code, storage paths, and model serialization.
- Future work should start here when a task changes schema, DAO behavior, model fields, JSON import/export compatibility, generated `.g.dart`, backup/restore shape, or cross-feature persistence invariants.

## Scope

- Drift database: `lib/core/database/app_database.dart`, `lib/core/database/tables/app_tables.dart`, `lib/core/database/dao/`, generated `*.g.dart`.
- Domain models: `lib/core/models/`, including `book/` and `source/` splits for base fields, logic, rules, and serialization.
- Storage abstractions: `lib/core/storage/`, `lib/core/services/book_storage_service.dart`, `book_cover_storage_service.dart`, `reader_chapter_content_store.dart`, `reader_chapter_content_storage.dart`, `app_storage_paths.dart`.
- DI registration: `lib/core/di/injection.dart`.
- Tests: `test/core/database/`, `test/core/models/`, and service tests that verify DAO/model contracts.

## Dependencies And Impact

- Depends on Drift, SQLite, `path_provider`, model serialization helpers, and service-level storage consumers.
- Downstream modules include Bookshelf, Book Detail, Reader Runtime, Source Manager, Discovery/Search, Settings/Cache, Backup/Restore, and Association import flows.
- Schema and model changes can require generated code updates via `dart run build_runner build --delete-conflicting-outputs`.

## Key Flows

- `AppDatabase` opens `inkpage_reader.db` under application support, declares schema version `1`, registers tables and DAOs, and uses generated Drift code.
- `app_tables.dart` maps Dart domain models to Drift tables and TypeConverters for rule objects and read config JSON.
- `Book` and `BookSource` expose Legado-compatible JSON surfaces through serialization helpers while keeping behavior split across `book_*` and `source_*` files.
- DAO registration in `configureDependencies()` makes database access available to services and providers through get_it.
- Reader chapter content is stored separately from chapter metadata through `ReaderChapterContents` and content-store services.

## Change Entry Points

- Schema/table changes: `lib/core/database/tables/app_tables.dart`, `lib/core/database/app_database.dart`, target DAO, generated `.g.dart`.
- Model field or JSON changes: `lib/core/models/book*.dart`, `lib/core/models/book/`, `lib/core/models/book_source*.dart`, `lib/core/models/source/`, relevant serialization file.
- DAO behavior: `lib/core/database/dao/*_dao.dart` and matching generated DAO file.
- Storage path or file ownership: `lib/core/storage/app_storage_paths.dart`, `lib/core/services/book_storage_service.dart`, content or cover storage service.
- Validation: smallest relevant DAO/model tests first, then downstream tests for affected feature modules.

## Change Routes

- Add a persisted field: update domain model, table column, serializer, copy/merge logic, DAO insert/update paths, generated Drift code, backup/restore if exported, and affected UI/provider tests.
- Change a primary key or cache key: start with the table/model contract, then update services that compose keys, cleanup paths, downloads, reader content cache, and source-switch behavior.
- Modify source JSON compatibility: update `BookSource` rule parsing/serialization, import preview, source manager tests, and rule engine compatibility tests.
- Change generated Drift declarations: run build_runner, inspect `.g.dart` diff, and include generated files only when they are part of the schema/DAO change.
- When persistence ownership or contracts change, update this module and every feature module whose data boundary moved.

## Known Risks

- `schemaVersion` is currently `1`; any schema evolution needs a deliberate migration strategy rather than silent destructive behavior.
- Generated Drift files are committed source in this repo; stale generated code can compile against outdated schema contracts.
- `Book` fields such as `chapterIndex`, `charOffset`, `visualOffsetPx`, and `readerAnchorJson` are reader-position contracts shared with Reader Runtime and Bookshelf sorting.
- `BookSource` JSON aims at Legado source compatibility; field renames or type coercion changes can break imports and source validation.
- Backup/restore relies on DAO/model serialization shape, not just table definitions.

## Reference Notes

- Useful Legado counterparts: `app/src/main/java/io/legado/app/data/AppDatabase.kt`, `data/entities/Book.kt`, `BookSource.kt`, `BookChapter.kt`, `BookProgress.kt`, `data/dao/`, and exported Room schemas under `app/schemas/io.legado.app.data.AppDatabase/`.
- Legado is useful for naming, long-term migration discipline, and source/book JSON semantics. It is not a mandate to copy Room migrations or all Legado entities such as RSS/audio/comic types into `reader`.

## Do Not Do

- Do not change persisted contracts from a feature page without updating model, DAO, tests, and generated code.
- Do not add unused Legado fields solely for parity when no target feature consumes them.
- Do not delete compatibility tables or DAO paths just because they are not visible in current UI; check backup/restore and import compatibility first.

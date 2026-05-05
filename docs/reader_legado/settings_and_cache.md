# Settings And Cache

## Current Responsibility

- Owns app preferences, reading/TTS/settings pages, reader-v2 preference repository, download task lifecycle, chapter content storage/preparation, cache manager UI, TTS service configuration, backup, restore, and settings-backed app behavior.
- Future work should start here when a setting does not persist/apply, download/cache state is inconsistent, chapter content storage changes, TTS settings drift, or backup/restore fails.

## Scope

- Settings state/UI: `lib/features/settings/settings_provider.dart`, `provider/settings_base.dart`, `settings_page.dart`, `*_settings_page.dart`, `font_provider.dart`, `lib/core/constant/prefer_key.dart`.
- Reader settings: `lib/features/reader_v2/features/settings/`.
- TTS/audio: `lib/core/services/tts_service.dart`, `audio_handler.dart`, reader-v2 TTS feature.
- Download/cache: `lib/core/services/download_service.dart`, `lib/core/services/download/`, `lib/features/cache_manager/download_manager_page.dart`.
- Chapter content storage: `reader_chapter_content_store.dart`, `reader_chapter_content_storage.dart`, `chapter_content_preparation_pipeline.dart`, `chapter_content_scheduler.dart`.
- Backup/restore/export: `backup_service.dart`, `restore_service.dart`, `export_book_service.dart`.
- Tests: `test/features/settings/`, `test/download_executor_test.dart`, `test/backup_service_test.dart`, `test/core/services/tts_state_test.dart`, content storage tests through reader/detail modules.

## Dependencies And Impact

- Depends on `SharedPreferences`, `PreferKey`, `AppConfig`, DAOs, `BookSourceService`, network service, `TTSService`, file/storage paths, and Data Model contracts.
- Impacts App Shell theme/locale, Reader Runtime layout/TTS/content, Book Detail cache/download entrypoints, Bookshelf batch download, Source Manager validation settings, backup/restore compatibility, and release diagnostics when configuration changes.
- Preference keys and backup schema are long-lived user data contracts.

## Key Flows

- `SettingsProvider` loads preferences from `SharedPreferences`, exposes setters, and notifies UI and dependent services.
- Reader-v2 settings repository maps shared preferences into reader layout/runtime settings.
- `DownloadService` composes base/scheduler/executor behavior, persists `DownloadTask`, and coordinates chapter content downloads.
- Content storage services separate chapter metadata from stored chapter content and track ready/failure state.
- Backup exports app data and config; restore validates manifest/schema before importing persisted state.
- TTS settings update both global `TTSService` and reader-v2 TTS controller behavior.

## Change Entry Points

- New or changed setting: `PreferKey`, `SettingsProvider`, relevant settings page, reader-v2 prefs repository if reader-facing.
- Download lifecycle: `download_service.dart`, `core/services/download/`, `download_manager_page.dart`, `DownloadDao`.
- Chapter content storage: `reader_chapter_content_*`, `chapter_content_*`, `ReaderChapterContentDao`.
- Backup/restore: `backup_service.dart`, `restore_service.dart`, model/DAO serialization.
- TTS: `tts_service.dart`, `features/reader_v2/features/tts/`, `tts_settings_page.dart`.
- Tests: `flutter test test/features/settings test/download_executor_test.dart test/backup_service_test.dart test/core/services/tts_state_test.dart`.

## Change Routes

- Add a preference: define key/default/load/setter, update settings UI, sync reader-v2 repository or service consumers, and add focused tests.
- Change download behavior: update service/scheduler/executor with DAO state transitions, then check Book Detail scheduling, Cache Manager UI, and download executor tests.
- Change content storage keys/state: synchronize Data Model, Reader Runtime, Book Detail cache status, backup/restore, and download filtering.
- Change backup format: update export and restore together, validate schema/manifest behavior, and add compatibility tests.
- Change TTS settings/service: update global service, settings provider, reader-v2 TTS controller/highlight, and TTS state tests.
- Update atlas docs when settings ownership, persistence contracts, or cache flows move between modules.

## Known Risks

- `SettingsProvider` loads many preferences; missing defaults or setters can make UI appear correct while persistence is broken.
- `DownloadService` loads tasks in its lifecycle; tests and repeated initialization can leak shared state if not isolated.
- Download tasks and content storage depend on chapter index, book URL, origin, and content keys; source switch or chapter rebuild can invalidate cache assumptions.
- `BackupService.currentSchemaVersion` follows database schema version; restore can reject incompatible manifests.
- Old `SharedPreferences` keys may still exist in user data even when current UI no longer exposes them.

## Reference Notes

- Useful Legado counterparts: `ui/config`, `help/config`, `ui/book/cache`, `service/DownloadService.kt`, `service/CacheBookService.kt`, `help/storage/Backup.kt`, `help/storage/Restore.kt`, read-aloud services.
- Legado is useful for separating settings pages from downstream services and for download/cache/backup recovery points. Feature parity is disabled, so extra Legado setting categories are not implied.

## Do Not Do

- Do not let settings pages directly mutate reader runtime internals; use provider/repository/controller boundaries.
- Do not rename or remove preference keys without migration and restore implications.
- Do not expand cache/download into new product features unless explicitly requested.

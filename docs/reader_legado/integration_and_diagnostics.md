# Integration And Diagnostics

## Current Responsibility

- Owns external app entrypoints, URI/share/file associations, import dialogs, local-file handoff, app/about diagnostics, crash log, app log, version reporting, update/release metadata, and release workflow orientation.
- Future work should start here when a task begins outside the app UI, import type detection is wrong, diagnostic evidence is missing, crash logs do not capture failures, or release publishing behavior changes.

## Scope

- Associations: `lib/features/association/association_handler_service.dart`, `handlers/association_base.dart`, `uri_association_handler.dart`, `file_association_handler.dart`, `association_dialog_helper.dart`.
- Diagnostics/about: `lib/features/about/`, `lib/core/services/crash_handler.dart`, `app_log_service.dart`, `app_version.dart`, `update_service.dart`.
- Import consumers: Source Manager import, Replace Rule provider, Bookshelf local-book import, local book parsers.
- Release workflow: `.github/workflows/android-release.yml`, `pubspec.yaml` version metadata, Android signing boundary.
- Tests: `test/import_logic_test.dart`, `test/local_txt_test.dart`, `test/app_exception_test.dart`, related local book and import tests.

## Dependencies And Impact

- Depends on `app_links`, `receive_sharing_intent`, file picker/path services, root navigation/context availability, `BookshelfProvider`, source import, replace-rule import, crash handler, app log, app version, and Android manifest associations.
- Impacts Source Manager imports, Replace Rules, Bookshelf/local books, App Shell navigation readiness, About/diagnostics UI, and user-visible error reporting.
- External callbacks can arrive while navigation and providers are still settling; mounted/context checks are part of the contract.

## Key Flows

- `AssociationHandlerService` receives external links/shares and delegates to URI or file handlers.
- `UriAssociationHandler` supports Legado/Yuedu-style schemes for source, replace-rule, and add-to-bookshelf style imports.
- `FileAssociationHandler` detects shared JSON or local book files and routes them to the matching import flow.
- Association dialog helpers present preview/confirmation before applying imports.
- `CrashHandler` captures Flutter/platform errors into crash logs; `AppLog` keeps recent logs and toast streams.
- Release CI runs focused reader-v2/source-manager checks before signed Android APK publishing on tag or manual workflow dispatch.

## Change Entry Points

- URI scheme/type mapping: `handlers/uri_association_handler.dart`.
- Shared file handling: `handlers/file_association_handler.dart`.
- Import dialogs: `handlers/association_dialog_helper.dart`, Source Manager import dialog, Replace Rule provider.
- Local-book handoff: `BookshelfProvider.importLocalBookPath()`, `LocalBookService`.
- Crash/log/about: `lib/core/services/crash_handler.dart`, `app_log_service.dart`, `lib/features/about/`.
- Release publishing: `.github/workflows/android-release.yml`, `pubspec.yaml`, Android signing configuration.

## Change Routes

- Add or alter URI support: update scheme/type mapping, import dialog route, target provider/service, and import tests.
- Change shared file import: update file type detection and target import flow, then verify local book copy strategy and JSON type inference.
- Change diagnostics: update crash/log service and about UI together, then verify startup failure panel and error-reporting surfaces.
- Change release flow: inspect AGENTS release rules, update CI workflow or version metadata, and validate focused checks named in the workflow.
- If external imports add new persisted data or source fields, update Data Model, Source Manager, Rules/Local Books, or Bookshelf docs accordingly.

## Known Risks

- External intent/share callbacks can run before the target page or provider is ready; check `mounted` and navigator availability.
- JSON type detection can misclassify sources, replace rules, themes, or local-book metadata if new import shapes overlap.
- Local-book file copies can collide on names or stale paths.
- Crash logging must not assume UI is available during startup failure.
- Release workflow depends on secrets and tag naming; do not test by pushing tags unless explicitly doing release work.

## Reference Notes

- Useful Legado counterparts: `ui/association`, `ui/about`, `help/IntentHelp.kt`, `help/IntentData.kt`, `help/CrashHandler.kt`, and `api.md`.
- Legado is useful for import type boundaries, user confirmation flows, and diagnostic surfaces. Feature parity is disabled, so additional import types such as RSS/theme/httpTTS are not implied unless requested.

## Do Not Do

- Do not perform full business logic inside intent/share handlers; route to the owning feature service/provider.
- Do not add external import types without explicit user-facing scope and tests.
- Do not alter release signing, secrets, or tag flow as part of unrelated diagnostics work.

# Project Rules

## Project Overview

- This is the Flutter/Dart project `inkpage_reader`.
- The app display name is `墨頁`.
- The product is a novel reader inspired by Legado.

## Architecture

- `lib/core` contains core models, database code, services, storage, network, utilities, and parsing engines.
- `lib/features` contains feature-specific UI, providers, and workflows.
- `lib/shared` contains shared widgets and theme code.
- `lib/features/reader_v2` is split by responsibility:
  - `application`: reader coordination and host logic.
  - `content`: chapter repositories and content transformation.
  - `layout`: layout specs and layout engine.
  - `render`: rendered page models and painters.
  - `runtime`: reader runtime state, resolving, progress, and preload scheduling.
  - `viewport`: scroll/slide viewport behavior and gesture handling.

## State And Services

- Use `provider` / `ChangeNotifier` for UI-facing state.
- Use `get_it` for global services and DAO access.
- When adding or changing global services, check both `lib/core/di/injection.dart` and `lib/app_providers.dart`.
- Keep feature providers close to their feature directory unless they are truly app-wide.

## Database

- Drift table definitions live in `lib/core/database/tables/app_tables.dart`.
- DAO implementations live in `lib/core/database/dao/`.
- `AppDatabase` registration lives in `lib/core/database/app_database.dart`.
- After changing Drift schema or DAO declarations, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

- Commit the generated `.g.dart` updates when they are part of the change.

## Testing

- Use `flutter test` for normal test runs.
- Use `tool/flutter_test_with_quickjs.sh` for tests involving QuickJS, JavaScript rules, or rule parsing behavior.
- Use `tool/run_source_validation.sh` for source validation batches.
- For focused changes, prefer the smallest relevant test first, then broaden if the behavior touches shared code.

## CI Focus

- Release CI currently runs focused checks around `reader_v2` and `source_manager`.
- Changes under those areas should prioritize:

```bash
flutter analyze lib/features/reader_v2 lib/features/source_manager test/features/reader_v2 test/features/source_manager
flutter test test/features/reader_v2 \
  test/features/source_manager/source_manager_provider_test.dart \
  test/features/source_manager/source_manager_page_smoke_test.dart \
  test/features/source_manager/source_login_test.dart
```

## Work Style

- Use Traditional Chinese for user-facing communication and project-rule discussion.
- Preserve existing Chinese comments and local naming style when editing nearby code.
- Avoid unrelated refactors while implementing a requested change.
- Do not commit build artifacts, local tool output, keystores, or secrets.
- Before changing an unfamiliar area, inspect the existing local pattern and follow it.

## Release Publishing

- Release publishing is handled by `.github/workflows/android-release.yml`.
- The workflow runs when a tag matching `v*` is pushed, and can also be started with `workflow_dispatch`.
- Standard release flow:

```bash
flutter pub get
flutter analyze lib/features/reader_v2 lib/features/source_manager test/features/reader_v2 test/features/source_manager
flutter test test/features/reader_v2 \
  test/features/source_manager/source_manager_provider_test.dart \
  test/features/source_manager/source_manager_page_smoke_test.dart \
  test/features/source_manager/source_login_test.dart
git tag vX.Y.Z
git push origin vX.Y.Z
```

- If version metadata changes are needed, update `pubspec.yaml` before tagging and commit that change first.
- After pushing the release tag, check GitHub Actions once and confirm the Android Release workflow has started building.
- Once the remote workflow is visibly building, it is acceptable to close the task without waiting for the build to finish.

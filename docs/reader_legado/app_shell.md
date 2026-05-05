# App Shell

## Current Responsibility

- 負責 `inkpage_reader` 的啟動殼層、DI、全域 Provider、根 `MaterialApp`、主導航、主題/語系套用、啟動畫面、啟動失敗回復、全域驗證協調器與 Workmanager 背景入口。
- 未來工作若發生在進入 feature 前、全域服務初始化、根 navigation、啟動錯誤畫面、延後初始化或 app-level provider 組裝，應從這裡開始。

## Scope

- 入口與根 app：`lib/main.dart`、`lib/app_providers.dart`。
- 啟動與主導航：`lib/features/welcome/splash_page.dart`、`startup_failure_panel.dart`、`main_page.dart`。
- 全域 DI：`lib/core/di/injection.dart`。
- 全域 UI 基礎：`lib/shared/theme/app_theme.dart`、`lib/shared/widgets/`、`lib/core/widgets/book_cover_widget.dart`。
- Android/build boundary：`android/`、`.github/workflows/android-release.yml` when the task is app shell or release wiring.
- Representative checks: `flutter analyze lib/main.dart lib/app_providers.dart lib/features/welcome` and relevant widget compile tests.

## Dependencies And Impact

- Depends on Drift `AppDatabase`, DAO registration, `NetworkService`, `TTSService`, `CrashHandler`, `DefaultData`, `SettingsProvider`, `BookshelfProvider`, `DownloadService`, `SourceVerificationCoordinator`, `Workmanager`, and `SharedPreferences`.
- Impacts all feature pages, global provider lifecycle, root navigator behavior, source verification routing, theme/locale propagation, startup recovery, and background update entrypoints.
- New global services usually require synchronized changes in `lib/core/di/injection.dart` and `lib/app_providers.dart`.

## Key Flows

- `main()` wraps `_startApp()` in `runZonedGuarded`, installs the Flutter error widget, configures dependencies, then runs `MultiProvider` with `LegadoReaderApp`.
- `LegadoReaderApp` consumes `SettingsProvider` for theme and locale, installs `rootNavigatorKey` and `SourceVerificationCoordinator`, then opens `SplashPage`.
- `SplashPage` runs `DefaultData.initEssential()` and navigates to `MainPage`; non-critical default data is deferred from `MainPage` through `DefaultData.initDeferred()`.
- `callbackDispatcher()` reinitializes DI inside the Workmanager isolate before reading bookshelf data for background tasks.
- Startup failure uses `_StartupFailureApp` and `StartupFailurePanel` with retry that resets get_it before restarting.

## Change Entry Points

- Startup/crash behavior: `lib/main.dart`, `lib/features/welcome/splash_page.dart`, `lib/features/welcome/startup_failure_panel.dart`.
- Root navigation: `lib/features/welcome/main_page.dart`, `rootNavigatorKey` usage in `lib/main.dart`.
- Global services: `lib/core/di/injection.dart`.
- Global state: `lib/app_providers.dart`.
- Theme and shared shell widgets: `lib/shared/theme/app_theme.dart`, `lib/shared/widgets/`.
- CI/release shell: `.github/workflows/android-release.yml`.

## Change Routes

- New global service: implement lifecycle in the service, register it in `configureDependencies()`, add Provider only if UI observes it, then check tests that initialize app providers.
- Startup sequence change: inspect required initialization in `lib/main.dart`, essential data in `SplashPage`, deferred data in `MainPage`, and error recovery before touching feature code.
- Root navigation change: update `MainPage` or navigator keys, then verify source verification, association flows, and splash-to-main transition still route correctly.
- Background task change: verify DI and service dependencies work in a background isolate and do not assume Provider state from the main isolate.
- If startup ownership, global providers, or root route contracts change, update this module and affected feature modules.

## Known Risks

- `configureDependencies()` registers singletons; retry code resets get_it first, but other repeated initialization paths can still duplicate registrations.
- Workmanager runs in a background isolate and cannot share main-isolate Provider state.
- `MaterialApp.builder` wraps all routes in `SourceVerificationCoordinator`; root navigator changes can break WebView or verification-code prompts.
- Deferred initialization failures currently log instead of blocking the app; later code must not assume all optional default data exists immediately.

## Reference Notes

- Useful Legado counterparts: `app/src/main/java/io/legado/app/ui/main/MainActivity.kt`, `MainViewModel.kt`, `ui/welcome/WelcomeActivity.kt`, `help/DefaultData.kt`, `help/CrashHandler.kt`.
- Reference guidance is limited to startup sequencing, recoverable failure UI, and keeping the main shell separate from feature-specific business logic.
- Do not treat Legado's Android activity/view model structure as the target architecture; `reader` uses Flutter widgets, Provider, get_it, and Drift.

## Do Not Do

- Do not move book-source parsing, reader runtime behavior, or feature-specific state into the app shell.
- Do not introduce new global providers when local feature ownership is enough.
- Do not change release signing, secrets, or generated Android artifacts unless the task explicitly targets release publishing.

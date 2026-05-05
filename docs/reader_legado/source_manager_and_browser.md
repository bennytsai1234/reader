# Source Manager And Browser

## Current Responsibility

- Owns book-source import, preview, list state, filtering, sorting, grouping, selection, share/export, editing, debug, batch validation, runtime health annotations, WebView login, verification-code prompts, cookie writeback, and source verification coordination.
- Future work should start here when a task involves source health, source JSON import/export, rule editing UI, source debug output, login/cookie behavior, browser verification, or source validation affecting search/detail/reader.

## Scope

- Source manager UI/state: `lib/features/source_manager/source_manager_provider.dart`, `source_manager_page.dart`, `source_editor_page.dart`, `source_group_manage_page.dart`, `source_subscription_page.dart`, `views/`, `widgets/`.
- Import service: `SourceImportService` inside `source_manager_provider.dart`.
- Debug/validation: `lib/core/services/check_source_service.dart`, `source_debug_service.dart`, `source_validation_context.dart`, `tool/source_validation_support.dart`, `tool/run_source_validation.sh`.
- Browser/verification: `lib/features/browser/`, `lib/core/services/source_verification_service.dart`, `cookie_store.dart`, `webview_data_service.dart`, `backstage_webview.dart`.
- Data/model: `BookSource`, `BookSourcePart`, `BookSourceDao`, source rule models.
- Tests: `test/features/source_manager/`, `test/features/browser/`, `test/core/services/check_source_service_test.dart`, `source_verification_service_test.dart`, `test/tool/source_validation_support_test.dart`.

## Dependencies And Impact

- Depends on source models/serialization, rule engine, network/cookie services, WebView, source validation context, DAO access, import dialogs, and QuickJS-enabled tests for rules.
- Impacts Discovery/Search, Book Detail, Reader Runtime, Rules And Local Books, Settings/Cache validation settings, and every source-backed content flow.
- Runtime health annotations and enabled flags are cross-module contracts; changing them affects source eligibility outside this module.

## Key Flows

- `SourceImportService` parses JSON/URL input, prepares preview rows, identifies add/update/no-change cases, disables non-text novel sources where required, and applies import results.
- `SourceManagerProvider` maintains visible-source cache, filters, sort mode, group state, selected sources, and batch actions.
- `CheckSourceService` runs staged validation for search, discovery, info, TOC, and content with timeout/cancel behavior and writes health information back to source group/comment.
- `SourceDebugService` and debug provider expose source-rule execution diagnostics.
- Browser verification routes through `SourceVerificationCoordinator`, `SourceVerificationService`, `BrowserProvider`, WebView, verification-code dialog, and CookieStore/WebView data services.

## Change Entry Points

- Import/preview/apply: `lib/features/source_manager/source_manager_provider.dart`, `widgets/import_preview_dialog.dart`.
- List filters/sort/selection: `source_manager_provider.dart`, `widgets/source_filter_bar.dart`, `source_batch_toolbar.dart`, `source_item_tile.dart`.
- Editor forms: `source_editor_page.dart`, `views/source_edit_*.dart`, `dynamic_form_builder.dart`, `widgets/rule_text_field.dart`.
- Validation: `lib/core/services/check_source_service.dart`, `source_validation_context.dart`, `tool/source_validation_support.dart`.
- Debug: `lib/features/source_manager/source_debug_provider.dart`, `lib/core/services/source_debug_service.dart`.
- Browser/login: `lib/features/browser/browser_provider.dart`, `source_verification_coordinator.dart`, `verification_code_dialog.dart`, `lib/core/services/source_verification_service.dart`.
- Tests: `flutter test test/features/source_manager test/features/browser test/core/services/check_source_service_test.dart test/core/services/source_verification_service_test.dart`.

## Change Routes

- Import behavior change: update parse/preview/apply logic, then sync source serialization, import preview UI, non-novel source tagging, and import tests.
- Filter/sort/group change: update provider cache invalidation and UI controls, then run smoke/provider tests.
- Validation strategy change: update `CheckSourceService` and `SourceValidationContext`, then verify health writeback, cleanup candidates, source eligibility, and CLI validation support.
- Login/verification change: update browser provider/coordinator/service together, then check cookie domain normalization, queueing, refetch-after-success behavior, and source login tests.
- Rule-editor field change: update model serialization, editor forms, import/export, and rule engine expectations together.
- If source health or source model contracts change, update Discovery/Search, Book Detail, Reader Runtime, Rules And Local Books, and Data Model docs as needed.

## Known Risks

- `CheckSourceService` writes health information into source group/comment; message format changes can break cleanup, grouping, or UI assumptions.
- Batch validation uses concurrency, stage timeout, source timeout, and cancellation; cancel-after-writeback and slow-source starvation are common failure modes.
- Non-text novel sources are currently disabled/tagged during import; source eligibility depends on that import-layer assumption.
- Browser verification can refetch HTML and write cookies; domain normalization bugs affect later rule execution.
- `SourceManagerProvider` uses a visible-source cache with dirty flags; new filters or sort keys must mark cache dirty.

## Reference Notes

- Useful Legado counterparts: `ui/book/source`, `ui/book/source/debug`, `ui/book/source/edit`, `ui/book/source/manage`, `ui/browser`, `ui/login`, `service/CheckSourceService.kt`, `help/source/SourceVerificationHelp.kt`.
- Legado is useful for staged health checks, separating source edit/debug/manage/login responsibilities, and keeping human verification out of non-interactive batches. Feature parity is disabled, so RSS/audio/comic source support is not implied.

## Do Not Do

- Do not turn WebView into a general browser product.
- Do not implement rule execution directly in source manager UI; use `core/engine` and `BookSourceService`.
- Do not add unsupported source types solely because Legado has them.

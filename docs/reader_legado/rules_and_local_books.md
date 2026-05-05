# Rules And Local Books

## Current Responsibility

- Owns the source-rule execution engine, URL analysis, CSS/JSONPath/XPath/regex parsing, JavaScript extensions and async bridge, WebBook parsers, replace rules, Chinese content conversion helpers, and local TXT/EPUB/UMD parsing.
- Future work should start here when source content is parsed incorrectly, Legado rule compatibility is in question, JS behavior differs, replacement output changes, or local-book import/read behavior is wrong.

## Scope

- Rule engine: `lib/core/engine/analyze_rule.dart`, `analyze_url.dart`, `rule_analyzer.dart`, `analyze_rule/`, `rule_analyzer/`, `parsers/`.
- JS bridge/extensions: `lib/core/engine/js/`, including encode, extension, and TTF query helpers.
- Web book services/parsers: `lib/core/engine/web_book/`, `lib/core/services/book_source_service.dart`.
- Reader content helpers: `lib/core/engine/reader/content_processor.dart`, `chinese_text_converter.dart`.
- Replace rules: `lib/features/replace_rule/`, reader-v2 replace-rule feature, `ReplaceRuleDao`.
- Local books: `lib/core/local_book/`, `lib/core/services/local_book_service.dart`, `epub_service.dart`, `resource_service.dart`, `encoding_detect.dart`.
- Tests/tools: `test/core/engine/`, `test/core/local_book/`, `test/core/models/replace_rule_test.dart`, `tool/flutter_test_with_quickjs.sh`.

## Dependencies And Impact

- Depends on `BookSource` rule models, network/cookie services, `flutter_js`, HTML/CSS/XPath/JSONPath packages, crypto/encoding helpers, EPUB/UMD/TXT parsers, and storage services.
- Impacts Discovery/Search, Book Detail, Reader Runtime content loading, Source Manager debug/validation, Settings/Cache replace-rule toggles, and local-book bookshelf import.
- Rule semantics are the source-compatibility core; parser changes require focused tests and, for JS, QuickJS-enabled test execution.

## Key Flows

- `AnalyzeUrl` builds source requests, applies headers/cookies/variables, and returns response data for parser stages.
- `AnalyzeRule`, `RuleAnalyzer`, and parser implementations evaluate source rules against HTML/JSON/text inputs.
- `WebBook` parsers convert source responses into search books, book info, chapter lists, and chapter content.
- JS helpers expose compatible extension functions and async promise handling for source rules.
- Replace rules transform chapter content before reader layout.
- Local book services detect supported formats, parse metadata/chapter indexes, and provide chapter content fallback for reader runtime.

## Change Entry Points

- Rule syntax or parser behavior: `lib/core/engine/analyze_rule.dart`, `rule_analyzer.dart`, `parsers/`.
- URL/request behavior: `lib/core/engine/analyze_url.dart`, `lib/core/services/network_service.dart`, `cookie_store.dart`, WebView/backstage paths if verification is involved.
- JS behavior: `lib/core/engine/js/`.
- Search/detail/toc/content parsing: `lib/core/engine/web_book/`, `lib/core/services/book_source_service.dart`.
- Replace rules: `lib/features/replace_rule/`, `lib/features/reader_v2/features/replace_rule/`, `lib/core/models/replace_rule.dart`.
- Local books: `lib/core/local_book/`, `lib/core/services/local_book_service.dart`, `epub_service.dart`.
- Tests: `tool/flutter_test_with_quickjs.sh test/core/engine`, plus local-book and replace-rule tests.

## Change Routes

- Change parser semantics: add or update focused fixtures in `test/core/engine`, then check search/detail/toc/content integration paths.
- Change URL/request handling: synchronize `AnalyzeUrl`, network/cookie/WebView boundaries, and Source Manager validation/debug expectations.
- Change JS extension/async bridge: update JS engine helpers and run QuickJS test script; verify timeout, promise, and result bridge behavior.
- Change local-book parsing: update format parser and `LocalBookService`, then verify bookshelf import, chapter offset/href handling, reader fallback, and backup implications.
- Change replace rules: update model/DAO/provider and reader content transformer together.
- If rule compatibility or local-book ownership changes, update Source Manager, Reader Runtime, Discovery/Search, Book Detail, and Data Model docs as needed.

## Known Risks

- Legado rule semantics are broad; `reader` has a Dart implementation and tests are the contract for what is actually supported.
- JS async rewrite, promise bridge, timeout, and extension APIs are fragile and need QuickJS-enabled tests.
- TXT uses byte offsets and charset; reparsing or moving files can invalidate saved chapter offsets.
- EPUB href/resource resolution and UMD cache behavior affect reader content fallback.
- Dict rules and TXT TOC rule tables/models exist for compatibility even if they are not prominent UI surfaces.

## Reference Notes

- Useful Legado counterparts: `model/analyzeRule`, `model/webBook`, `help/JsExtensions.kt`, `help/ReplaceAnalyzer.kt`, `ui/replace`, `model/localBook`, and `modules/book`.
- Legado is useful for conceptual rule semantics and local-book format boundaries. Do not assume all Kotlin behavior is implemented in Dart unless reader tests or code prove it.

## Do Not Do

- Do not change parser semantics without tests that name the intended compatibility behavior.
- Do not put UI workflow logic into engine/parser files.
- Do not add new local formats, source types, or full Legado parity unless explicitly requested.

# Discovery And Search

## Current Responsibility

- Owns source-driven discovery categories, paged discovery results, cross-source search execution, search history, search scope, result filtering/sorting, and routing search/explore results into Book Detail.
- Future work should start here when results are missing before detail load, search cancellation/order is wrong, discovery pagination is stale, or source eligibility changes visible search/explore behavior.

## Scope

- Explore: `lib/features/explore/explore_provider.dart`, `explore_page.dart`, `explore_show_provider.dart`, `explore_show_page.dart`.
- Search: `lib/features/search/search_model.dart`, `search_provider.dart`, `search_page.dart`, `models/search_scope.dart`, `widgets/`.
- Engine/service boundary: `lib/core/engine/explore_url_parser.dart`, `lib/core/engine/web_book/`, `lib/core/services/book_source_service.dart`.
- Data: `SearchBookDao`, `SearchKeywordDao`, `BookSourceDao`, `BookshelfStateTracker`.
- Tests: `test/features/explore/`, `test/features/search/`, and engine parser tests when rule parsing changes.

## Dependencies And Impact

- Depends on source availability, source runtime health, `BookSourceService`, `WebBook`, rule parsers, search/explore URLs, cancellation tokens, search history storage, and bookshelf markers.
- Impacts Book Detail entry data, source switch candidates, cover search, Source Manager health policies, and Settings preferences that affect precision/search behavior.
- Source validation or import changes can alter which sources participate in discovery/search.

## Key Flows

- `ExploreProvider` watches source parts from `BookSourceDao`, parses `exploreUrl` through `ExploreUrlParser`, and exposes available categories.
- `ExploreShowProvider` calls `WebBook.exploreBookAwait`, manages paging, and uses request serials to avoid stale responses overwriting newer category state.
- `SearchProvider` manages UI state, search history, scope, filters, and delegates concurrent work to `SearchModel`.
- `SearchModel` runs multi-source search with cancellation and result merging, then persists `SearchBook` records.
- Results route into Book Detail, where final book info and TOC are loaded.

## Change Entry Points

- Explore category parsing: `lib/core/engine/explore_url_parser.dart`, `lib/features/explore/explore_provider.dart`.
- Explore result paging: `lib/features/explore/explore_show_provider.dart`.
- Search concurrency/merge/sort: `lib/features/search/search_model.dart`.
- Search UI state, history, scope, filters: `lib/features/search/search_provider.dart`, `widgets/search_scope_sheet.dart`, `models/search_scope.dart`.
- Eligibility from source health: `lib/core/services/check_source_service.dart`, `lib/features/source_manager/`.
- Tests: `flutter test test/features/explore test/features/search`.

## Change Routes

- Change explore categories: update parser and provider, then verify source `enabledExplore`, runtime health, category cache keys, and explore tests.
- Change paged result behavior: update `ExploreShowProvider` request serial/pagination state and verify stale responses cannot overwrite new results.
- Change search result merging: update `SearchModel` normalization, duplicate grouping, relevance, and source-origin handling, then sync provider filters and source-switch expectations.
- Change source eligibility: coordinate with Source Manager And Browser so health tags, disabled flags, and source filters stay consistent.
- If discovery/search contracts change, update Book Detail and Source Manager docs if their routing or eligibility assumptions changed.

## Known Risks

- Search uses shared cancellation and concurrent source calls; stale results can corrupt a newer search if generation checks are bypassed.
- `ExploreShowProvider` relies on request serial protection for refresh/pagination.
- Precision search and normalization affect test expectations and source-switch candidate ranking.
- Explore category caching is keyed by source URL and explore URL; changing parser semantics can leave old categories misleading unless cache invalidation is considered.

## Reference Notes

- Useful Legado counterparts: `ui/main/explore`, `ui/book/explore`, `ui/book/search`, `ui/book/searchContent`, and `model/webBook/SearchModel.kt`.
- Legado is useful for concurrent source search, pause/cancel patterns, result merging, and separating explore/search concerns. It is not a mandate to add search-content parity or RSS discovery.

## Do Not Do

- Do not place source editing, login, or validation logic inside search/explore providers.
- Do not add Legado search variants unless explicitly requested.
- Do not bypass Book Detail for final book info and chapter loading.

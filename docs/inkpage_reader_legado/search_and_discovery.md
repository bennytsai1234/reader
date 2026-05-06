# 搜尋與發現

## 目前責任

- 提供多書源並行搜尋、搜尋歷史、搜尋範圍、結果合併、排序、篩選與書架狀態標記。
- 提供發現頁書源列表、分組、探索分類展開、分類快取與探索結果頁。

## 範圍

- Search：`lib/features/search/`。
- Explore：`lib/features/explore/`。
- Core flow：`SearchModel`、`SearchScope`、`ExploreUrlParser`、`BookSourceService.exploreBooks()`。
- 測試：`test/features/search/`、`test/features/explore/`、`test/core/engine/explore_url_parser_test.dart`。

## 依賴與影響

- 依賴啟用的書源、source group、search/explore rule、WebBook pipeline、搜尋快取 DAO 與書架狀態 tracker。
- 下游影響書籍詳情入口、加入書架流程、發現頁體驗與 source manager 的 source health 觀感。
- 搜尋結果的合併與排序會影響使用者是否看到同一本書的多來源資訊。

## 關鍵流程

- `SearchProvider` 載入搜尋範圍、來源分組、精準搜尋偏好與歷史紀錄。
- `SearchModel` 使用 pool 依來源並行呼叫 `WebBook.searchBookAwait()`，回報進度、失敗來源與成功結果。
- 結果會依精準匹配、包含匹配、來源數與使用者選擇排序。
- `ExploreProvider` watch 可發現來源，依分組或關鍵字過濾，展開某來源後解析 `ExploreKind`。
- `ExploreShowProvider` 使用具體 explore URL 載入探索結果並進入書籍詳情。

## 常見修改起點

- 搜尋沒有進度或取消異常：先看 `SearchModel`。
- 搜尋範圍、來源篩選、結果排序：先看 `SearchProvider` 與 `SearchScope`。
- 搜尋結果合併錯誤：先看 `SearchBook` model 與 `SearchModel._mergeItems`。
- 發現頁分類、分組、展開快取：先看 `ExploreProvider`。
- 探索結果載入：先看 `ExploreShowProvider` 與 `BookSourceService.exploreBooks()`。

## 修改路線

- 改搜尋併發或 timeout 時，同步 UI 進度、失敗統計與 tests。
- 改結果合併時，同步書籍詳情入口與 bookshelf state tracker。
- 改發現分類解析時，同步 `ExploreUrlParser` tests 與 UI compile/smoke tests。

## 已知風險

- 搜尋併發數來自 preference，過高可能造成來源失敗或 throttling。
- 不同來源對同一本書的 URL/作者/名稱不一致，合併邏輯需要保守。
- ExploreKind cache key 依書源 URL 與 exploreUrl 組合，規則變更要能清快取。

## 參考備註

- Legado 對應區域是 `model/webBook/SearchModel.kt`、`ui/book/search`、`ui/main/explore`、`ui/book/explore`。
- 可參考 Legado 的並行搜尋、結果合併與 explore 分類概念；不要把搜尋內容、RSS 或其他外部入口視為必備功能。

## 不要做

- 不要把搜尋 UI 的排序需求直接塞進 WebBook parser。
- 不要讓發現頁修改 source rule；source rule 仍由 source manager/editor 管理。
- 不要為追 Legado 額外搜尋入口而新增本專案沒有的產品流程。

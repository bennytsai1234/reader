# Discovery And Search

## Reader 現況

- 發現 / 探索：`lib/features/explore`
- 搜尋：`lib/features/search`
- 主要入口：
  - `lib/features/explore/explore_page.dart`
  - `lib/features/explore/explore_show_page.dart`
  - `lib/features/search/search_page.dart`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/models`、`lib/core/services/book_source_service.dart`、`lib/core/engine`、`lib/features/source_manager`
- 直接下游影響：`lib/features/book_detail`，以及從探索結果、搜尋結果導向書籍詳情的流程

## Legado 對照

- 首頁探索：`legado/app/src/main/java/io/legado/app/ui/main/explore`
- 書籍探索：`legado/app/src/main/java/io/legado/app/ui/book/explore`
- 搜書：`legado/app/src/main/java/io/legado/app/ui/book/search`
- 搜內文：`legado/app/src/main/java/io/legado/app/ui/book/searchContent`

## 可借鏡的方向

- 探索頁資料載入與切頁方式
- 搜書與搜內文如何分開責任
- 搜尋結果、搜尋條件、來源切換如何維持狀態一致

## 不要做的事

- 不把探索頁擴張成更大的內容平台
- 不因為 `legado` 有更多搜尋變體就擴增需求

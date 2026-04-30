# Bookshelf

## Reader 現況

- 主要資料夾：`lib/features/bookshelf`
- 入口檔案：
  - `lib/features/bookshelf/bookshelf_page.dart`
  - `lib/features/bookshelf/bookshelf_provider.dart`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/database`、`lib/core/models`、`lib/core/services/bookshelf_state_tracker.dart`、`lib/core/services/check_source_service.dart`
- 直接下游影響：`lib/features/book_detail`、`lib/features/reader_v2`，以及從主導航進入書本的主要閱讀流程

## Legado 對照

- 主書架：`legado/app/src/main/java/io/legado/app/ui/main/bookshelf`
- 書籍管理相關：`legado/app/src/main/java/io/legado/app/ui/book/manage`
- 分組相關：`legado/app/src/main/java/io/legado/app/ui/book/group`

## 可借鏡的方向

- 書架列表刷新與回首頁重載策略
- 分組、排序、批次操作的責任切分
- 書架狀態與資料更新如何分離

## 不要做的事

- 不因為 `legado` 有更多書架操作就直接複製功能面
- 只處理 `reader` 已有的書架能力與使用問題

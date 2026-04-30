# Book Detail

## Reader 現況

- 主要資料夾：`lib/features/book_detail`
- 子區塊：`lib/features/book_detail/source`
- 代表檔案：
  - `lib/features/book_detail/book_detail_page.dart`
  - `lib/features/book_detail/book_detail_provider.dart`
  - `lib/features/book_detail/change_cover_sheet.dart`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/database`、`lib/core/models`、`lib/core/services/book_source_service.dart`、`lib/core/services/download_service.dart`、`lib/core/services/reader_chapter_content_store.dart`
- 直接下游影響：`lib/features/reader_v2`、`lib/features/source_manager`，以及換源、換封面、下載、從詳情頁開啟閱讀等流程

## Legado 對照

- 書籍資訊：`legado/app/src/main/java/io/legado/app/ui/book/info`
- 目錄：`legado/app/src/main/java/io/legado/app/ui/book/toc`
- 換源：`legado/app/src/main/java/io/legado/app/ui/book/changesource`
- 換封面：`legado/app/src/main/java/io/legado/app/ui/book/changecover`

## 可借鏡的方向

- 書籍詳情頁如何拆資訊區、目錄區、操作區
- 換源流程如何與閱讀進度、章節資料分離
- 換封面與書本主資料如何避免互相污染

## 不要做的事

- 不把詳情頁做成大一統控制中心
- 不為了比齊 `legado` 而新增 `reader` 沒有的頁面分支

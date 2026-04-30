# Reader Runtime

## Reader 現況

- 閱讀主線：`lib/features/reader_v2`
- 主要子分層：
  - `application`
  - `content`
  - `layout`
  - `runtime`
  - `viewport`
  - `render`
  - `shell`
  - `features`
- 閱讀器內功能：
  - `lib/features/reader_v2/features/tts`
  - `lib/features/reader_v2/features/auto_page`
  - `lib/features/reader_v2/features/bookmark`
  - `lib/features/reader_v2/features/settings`
  - `lib/features/reader_v2/features/replace_rule`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/database`、`lib/core/models`、`lib/core/services/book_source_service.dart`、`lib/core/services/reader_chapter_content_storage.dart`、`lib/core/services/reader_chapter_content_store.dart`、`lib/core/engine`、`lib/features/reader_v2/content`、`lib/features/reader_v2/layout`
- 直接下游影響：`lib/features/reader_v2/viewport`、`lib/features/reader_v2/render`、`lib/features/reader_v2/features/*`，以及從 `lib/features/book_detail`、`lib/features/bookshelf` 進入的主閱讀流程

## Legado 對照

- 閱讀主畫面：`legado/app/src/main/java/io/legado/app/ui/book/read`
- 閱讀主模型：`legado/app/src/main/java/io/legado/app/model`
- 閱讀翻頁設定：`legado/app/src/main/java/io/legado/app/constant`
- 朗讀與閱讀服務：`legado/app/src/main/java/io/legado/app/ui/book/audio`、`legado/app/src/main/java/io/legado/app/service`
- 代表檔案：
  - `legado/app/src/main/java/io/legado/app/model/ReadBook.kt`
  - `legado/app/src/main/java/io/legado/app/model/ReadAloud.kt`
  - `legado/app/src/main/java/io/legado/app/constant/PageAnim.kt`

## 可借鏡的方向

- 閱讀器畫面殼層、狀態核心、視口控制如何切責任
- Scroll 與 Slide 模式如何分離
- 章節切換、進度同步、排版重算如何穩定運作
- TTS、書籤、自動翻頁、閱讀器內設定如何掛在核心外層

## 不要做的事

- 不把 `legado` 舊結構直接搬進 `reader_v2`
- 不為了對齊 `legado` 而破壞 `reader_v2` 已經分出的層次

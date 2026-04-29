# Reader V2 Plan

日期：2026-04-29

## 目的

`lib/features/reader_v2/` 是新的閱讀器主幹。它不是在舊 reader 上繼續加相容層，而是在同一個 repo 內重新建立一條乾淨資料流，等核心、runtime、viewport、painter 都完成並通過測試後，再切換入口。

舊的 `lib/features/reader/` 暫時保留為目前可執行版本，只做 bug fix，不再把新架構塞回舊過渡模型裡。

## 原則

- 不開另一個 repo，避免資料模型、設定、書源、TTS、DB、測試環境全部分叉。
- 不停用測試。舊 reader 測試保護現在的可用版本，v2 測試保護新架構邊界。
- 不在 v2 裡引入 `TextPage`、`PageCache`、`LineLayout.fromPages()`。
- 不讓 page 保存第二份 lines。page 只能是 `ChapterLayout.lines` 的切片。
- 不把 scroll / slide 做成兩套 layout。模式只影響 viewport 位移。

## V2 資料流

```text
ReaderV2Content
  -> ReaderV2LayoutSpec
  -> ReaderV2LayoutEngine
  -> ReaderV2ChapterLayout
  -> future PageResolverV2
  -> future ReaderRuntimeV2
  -> future Scroll / Slide Viewport V2
  -> future ReaderTilePainterV2
```

## 已建立的核心

### ReaderV2Content

位置：

```text
lib/features/reader_v2/engine/reader_v2_content.dart
```

職責：

```text
只處理章節原文正規化，產生唯一 displayText。
```

輸入：

```text
chapterIndex
title
rawText
```

輸出：

```text
chapterIndex
title
paragraphs
plainText
displayText
bodyStartOffset
contentHash
```

規則：

- `displayText` 是唯一文字真相。
- `charOffset` 對應 `displayText`，標題也算在內。
- `paragraphs` 只服務排版，不是第二份閱讀進度真相。

### ReaderV2LayoutSpec

位置：

```text
lib/features/reader_v2/engine/reader_v2_layout_spec.dart
```

職責：

```text
把手機可用尺寸與閱讀樣式收斂成 layout input。
```

輸出：

```text
viewportSize
contentWidth
contentHeight
style
layoutSignature
```

規則：

- layout cache 之後應該使用 `contentHash + layoutSignature`。
- scroll / slide 不應改變 layoutSignature，除非實際內容寬高或文字樣式改變。

### ReaderV2LayoutEngine

位置：

```text
lib/features/reader_v2/engine/reader_v2_layout_engine.dart
```

職責：

```text
唯一負責斷行與分頁，輸出 ReaderV2ChapterLayout。
```

輸入：

```text
ReaderV2Content
ReaderV2LayoutSpec
```

輸出：

```text
ReaderV2ChapterLayout
```

規則：

- 每一行在這裡切乾淨，包含標題、段落、硬換行、字元 offset、top/bottom/baseline。
- `ReaderV2TextLine.top/bottom` 永遠是章節內連續座標。
- 分頁只產生 `ReaderV2PageSlice`，不複製另一份 page-local lines。

### ReaderV2ChapterLayout

位置：

```text
lib/features/reader_v2/engine/reader_v2_layout.dart
```

職責：

```text
唯一 layout truth。
```

資料：

```text
displayText
lines
pages
contentHeight
contentHash
layoutSignature
```

查詢：

```text
linesForPage(pageIndex)
pageForCharOffset(charOffset)
lineForCharOffset(charOffset)
lineAtOrNearLocalY(localY)
pageForLine(line)
pageForLocalY(localY)
linesForRange(startCharOffset, endCharOffset)
```

規則：

- `lines` 是唯一 line truth。
- `pages` 是 line range 和 viewport range，不是第二份 line truth。
- painter 需要頁內座標時，用：

```text
pageLocalY = line.top - page.localStartY
```

## 後續順序

1. 建立 `PageResolverV2`：只載入章節、快取 layout、找前後 page slice。
2. 建立 `ReaderRuntimeV2`：只管閱讀狀態、進度、模式切換，不重新 layout。
3. 建立 `ScrollReaderViewportV2` / `SlideReaderViewportV2`：只管手勢、位移和可視 anchor。
4. 建立 `ReaderTilePainterV2`：只接收 page slice + lines 並畫到 Canvas。
5. 手機實測 v2，確認上下滾動、左右平移、跨章、恢復進度、TTS 跟隨。
6. v2 通過後，切換 `ReaderPage` 入口，再刪除舊 reader 過渡模型。

## 驗證入口

目前 v2 核心測試：

```bash
flutter test test/features/reader_v2
```

目前 v2 還沒有接 UI，不能取代現有 `ReaderPage`。

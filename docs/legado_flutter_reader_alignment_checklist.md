# Legado Flutter Alignment Checklist

更新日期：2026-03-20  
依據：目前 repo 內 Android legado 與 Flutter 閱讀器程式碼。  
目的：把閱讀器核心鏈拆成「已對齊 / 部分對齊 / 尚未對齊」。

## 已對齊

### 1. 閱讀器主控入口已集中

- legado：`ReadBook`
- Flutter：`ReadBookController`

判定：

- Flutter 現在不是 `ReaderProvider + 多個 mixin` 分散對外暴露，而是由 `ReadBookController` 當主控入口
- `ReaderProvider` 已退成薄包裝

### 2. scroll / slide 已改成單一 runtime 外層切模式

- legado：`ReadView + PageDelegate`
- Flutter：`ReadViewRuntime + ScrollModeDelegate / SlideModeDelegate`

判定：

- 兩邊都已是「單一閱讀視圖 runtime」加上「delegate 切模式」
- 這不再是兩條完全分裂的顯示鏈

### 3. 核心閱讀進度都回到章節字元位置

- legado：`durChapterIndex + durChapterPos`
- Flutter：`book.durChapterIndex + book.durChapterPos`

判定：

- Flutter scroll/slide 最後都會換算回 char offset
- 這是和 legado 很核心的一致點

### 4. 朗讀高亮已接回閱讀位置主鏈

判定：

- Flutter 的 `ReadAloudController` 會根據 `offsetMap` 更新 `ttsStart / ttsEnd`
- scroll 模式能回推章節位置
- slide 模式能回推 page index

這表示「朗讀不是獨立播放器」，而是已掛回閱讀器位置系統。

### 5. slide 模式已由 runtime chapter 組裝頁面

判定：

- `ReadBookController.buildSlideRuntimePages()` 現在是從 `prev/current/next ReaderChapter` 組合 slide pages
- 方向上已貼近 legado 的前中後章 runtime 思維

## 部分對齊

### 1. 章節 runtime 已存在，但厚度還不夠

- legado：`TextChapter`
- Flutter：`ReaderChapter`

目前狀態：

- Flutter 已有 `ReaderChapter`
- 但目前主要仍是 `pages` 容器加少量 helper
- 還沒有 legado `TextChapter` 那種更完整的章內狀態與能力密度

### 2. 分頁已回到 runtime 主鏈，但責任仍較分散

- legado：`ChapterProvider` 很厚，直接是 runtime 核心
- Flutter：`ChapterContentManager + ChapterProvider.paginate + ReaderChapterProvider`

目前狀態：

- Flutter 能完成同樣任務
- 但 runtime、內容快取、純分頁、chapter 包裝還是拆成多段
- 維護性比較好，但同構度還不是 1:1

### 3. 前中後章 runtime 思維已建立，但載入模型仍偏快取導向

目前狀態：

- Flutter 已有 `prevChapterRuntime / curChapterRuntime / nextChapterRuntime`
- 但底層仍主要依賴 `chapterPagesCache + ChapterContentManager window`
- 也就是「runtime 視角」有了，但「資料生命週期」仍偏 cache system

### 4. 朗讀跨頁/跨章規則大致對齊，但仍是 controller 直控 service

目前狀態：

- Flutter 已補上 slide 模式頁內前後移動優先，再跨章
- 已有 next chapter prefetch session
- 但播放控制仍是 `ReadAloudController -> TTSService`

所以能力鏈有了，抽象層級仍比 legado 淺。

### 5. 正文處理已往 legado 靠近，但還不能說等同

目前狀態：

- Flutter `ContentProcessor` 已補強 title/content rule scope、排序、re-segment
- 但整體深度仍不像 legado `ContentProcessor` 那麼完整

## 尚未對齊

### 1. 沒有 legado 等級的 `TextChapter` runtime

尚缺：

- 更完整章內 page/offset/navigation runtime
- 更完整的 chapter-level layout state
- 更接近 legado 的章節運行實體，而不只是 pages 包裝

### 2. 沒有朗讀 service abstraction

- legado：`ReadAloud -> BaseReadAloudService -> TTS/HTTP service`
- Flutter：`ReadAloudController -> TTSService`

尚缺：

- service layer
- foreground read aloud lifecycle abstraction
- 多引擎可替換結構

### 3. 沒有多引擎朗讀架構

目前狀態：

- `HttpTtsService` 已移除
- 現在是刻意只保留系統 TTS

所以這塊不是「做不好」，而是目前產品決策上先不做。

### 4. `ChapterProvider` 還不是 legado 那種單一中心

尚缺：

- view style
- text paint
- chapter build
- page build
- layout progress

這些在 Flutter 仍分散在多個模組之間。

## 總表

| 項目 | 狀態 | 說明 |
|---|---|---|
| 閱讀器主控入口 | 已對齊 | `ReadBookController` 已對齊 `ReadBook` 的角色 |
| scroll / slide 模式切換 | 已對齊 | 已是單一 runtime + delegate |
| 核心進度模型 | 已對齊 | 兩邊都回到 chapter char offset |
| 朗讀高亮與閱讀位置同步 | 已對齊 | 已能跟隨 scroll/slide 更新 |
| slide 由前中後章 runtime 組頁 | 已對齊 | 已具 legado 方向 |
| 章節 runtime 存在 | 部分對齊 | `ReaderChapter` 還比 `TextChapter` 薄 |
| 分頁鏈接回 runtime | 部分對齊 | 已完成，但責任較分散 |
| 前中後章的資料生命週期 | 部分對齊 | 仍偏快取系統，不是完整 runtime 主導 |
| 朗讀跨章/跨頁控制 | 部分對齊 | 行為接近，但抽象層不夠深 |
| 正文處理 | 部分對齊 | 已補強，但還不等於 legado |
| `TextChapter` 等級 runtime | 尚未對齊 | 還缺完整章內運行模型 |
| 朗讀 service abstraction | 尚未對齊 | 還沒有 service layer |
| 多引擎朗讀架構 | 尚未對齊 | 目前刻意只保留系統 TTS |
| `ChapterProvider` 單一中心化 | 尚未對齊 | Flutter 仍是多模組分工 |

## 最後結論

如果只用一句話總結：

> Flutter 閱讀器現在已經對齊 legado 的主幹，但還沒有完全對齊 legado 的厚 runtime 與 service 化層次。

換成工程判讀：

- 已對齊的是「控制鏈」
- 部分對齊的是「章節與分頁 runtime 密度」
- 尚未對齊的是「service abstraction 與完整 chapter runtime」

# Reader V2 閱讀器

## 目前責任

- 提供主要小說閱讀體驗：開書、章節載入、內容轉換、排版、渲染、滑動/滾動 viewport、閱讀進度、預載、設定、選單、朗讀、自動翻頁、替換規則與書籤。

## 範圍

- Application：`lib/features/reader_v2/application/`。
- Content：`lib/features/reader_v2/content/`。
- Layout/render/runtime/viewport：`lib/features/reader_v2/layout/`、`render/`、`runtime/`、`viewport/`。
- Reader features：`features/menu`、`features/settings`、`features/tts`、`features/auto_page`、`features/bookmark`、`features/replace_rule`。
- Shell：`lib/features/reader_v2/shell/`.
- 測試：`test/features/reader_v2/`。

## 依賴與影響

- 依賴 Book/Chapter/Content/Bookmark DAO、BookStorageService、LocalBookService、BookSourceService、TTSService、SharedPreferences 與替換規則。
- 下游影響閱讀進度持久化、書架排序、書籤、TTS、下載快取、內容替換與使用者設定。
- Reader V2 是 release CI 的重點區域之一。

## 關鍵流程

- `ReaderV2Page` 建立 `ReaderV2ControllerHost` 與 page coordinator。
- Host 初始化 settings/menu/viewport/dependencies，依 viewport size 與 style 建立 runtime。
- Runtime 透過 chapter repository 取得章節與內容，layout engine 切頁，render layer 畫出文字。
- Viewport 分為 scroll 與 slide 模式，透過 position tracker、page cache manager 與 visible page calculator 維持位置。
- Progress controller 保存 chapter index、char offset 與 visual offset，支援重開書後恢復。
- TTS controller 追蹤朗讀 highlight，自動翻頁 controller 依 viewport extent 推進。

## 常見修改起點

- 開書、離開、選單操作：先看 `ReaderV2Page`、`ReaderV2ControllerHost`、`ReaderV2PageCoordinator`。
- 章節內容來源：先看 `ReaderV2ChapterRepository` 與 `ReaderV2Dependencies`。
- 內容清理或替換：先看 `ReaderV2ContentTransformer`。
- 頁面切分：先看 `ReaderV2LayoutEngine`、`ReaderV2LayoutSpec`、`ReaderV2Style`。
- 渲染異常：先看 `render/` 的 page、tile、painter 與 text adapter。
- 滑動/滾動定位：先看 `viewport/` 與 `ReaderV2Runtime`。
- 設定、朗讀、自動翻頁或書籤：先看 `features/` 下對應 controller。

## 修改路線

- 改閱讀版面時，同步 layout spec、settings controller、shell 顯示與 viewport tests。
- 改定位或進度時，同步 runtime state、progress controller、Book model 欄位與書架/詳情入口。
- 改內容來源時，同步線上書、本地書、已下載章節與 content cache。
- 改 TTS/autopage 時，同步 runtime listener、viewport extent 與 UI controls。

## 已知風險

- Reader V2 模組切得細，但行為跨 application/content/layout/render/runtime/viewport；局部修補可能破壞定位或快取。
- 滑動與滾動模式共享 runtime state，但 viewport 行為不同，測試要涵蓋兩者。
- 字體、行高、段距、繁簡轉換與替換規則都會改變內容長度，進度保存需保守。

## 參考備註

- Legado 對應區域是 `ui/book/read`、`ui/book/read/page`、`model/ReadBook.kt`、`model/ReadAloud.kt`。
- 可參考 Legado 的章節 provider、page factory、閱讀設定與朗讀概念。
- 不要求補齊 Legado 的仿真翻頁、漫畫閱讀、文字動作選單或全部閱讀設定。

## 不要做

- 不要為單一 UI 顯示問題直接改 progress key 或 chapter identity。
- 不要把 parser/network 行為塞進 Reader V2；內容來源應走 repository/service。
- 不要只測一種 viewport 模式就宣稱閱讀器定位穩定。

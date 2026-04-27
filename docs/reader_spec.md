# 閱讀器規格

這份文件只記錄目前程式碼中已存在、可驗證的閱讀器行為。

## 範圍

閱讀器目前正式範圍：

1. 閱讀頁 shell 與選單
2. `slide` / `scroll` 兩種閱讀模式
3. 章節載入、正文 materialize、分頁與預載
4. `chapterIndex + charOffset` 進度保存與還原
5. 字級、行距、段距、縮排、繁簡轉換等閱讀設定
6. 系統 TTS 朗讀入口
7. 簡單自動翻頁
8. 書籤
9. 單章換源與整書 fallback 換源入口

## Durable Location

唯一可持久化閱讀座標：

```text
chapterIndex + charOffset
```

這代表：

- `pageIndex` 不作為長期進度真源。
- scroll offset 不作為長期進度真源。
- 切換模式、重新排版、重新進入閱讀器時，都要回到同一個章內字元位置。

## 開書與還原

打開閱讀器時：

1. 優先使用 `ReaderOpenTarget.location`。
2. 否則使用 `Book.chapterIndex` / `Book.charOffset`。
3. `ReaderRuntime.openBook()` 先確保章節目錄存在。
4. 初始 location normalize 後投影成目前頁面。

退出或 app 進入背景時會 flush pending progress。

## 章節與正文

章節目錄來源順序：

1. caller 傳入的 `initialChapters`
2. 本地 `chapters` table
3. 書源 `BookSourceService.getChapterList()`

正文來源順序：

1. `reader_chapter_contents` materialized content
2. 書源 / 本地書 materialize pipeline
3. `chapter.content` fallback

正文載入後會經過替換規則、分段、標題處理與繁簡轉換，再送入排版。

## Slide 模式

`slide` 模式使用三頁窗口：

- previous
- current
- next

PageView 的中心頁固定為 index `1`。翻到上一頁或下一頁時，runtime 更新窗口後 viewport recenter。

跨章時：

- 下一頁可接到下一章章首。
- 上一頁可接到上一章章末。
- durable progress 仍保存為目標章節的 `charOffset`。

## Scroll 模式

`scroll` 模式由 viewport 管理頁面偏移與 fling。跨過頁面高度時，runtime 推進或回退 `PageWindow`。

拖曳或慣性結束後，viewport 將視覺位置回推成 `ReaderLocation`，再交給 runtime 更新 visible location 與 debounce save。

## 設定變更

會觸發重新排版的設定包含：

- 字級
- 行距
- 段距
- 字距
- 縮排
- 左右與上下 padding
- 文字對齊
- page turn mode

重新排版後，位置以目前 `visibleLocation` 回推，不以舊頁碼回推。

會觸發重新載入內容的設定包含：

- 繁簡轉換
- 其他會改變正文 materialized result 的設定

## TTS

目前主線 TTS 行為：

- 從目前 visible location 開始朗讀。
- 讀取目前章節內容，從 `charOffset` 切出剩餘文字。
- rate、pitch、language 寫入 `SharedPreferences`。
- `highlightLocation` 可由朗讀起點與目前字詞 offset 推回。

目前不承諾：

- TTS 自動推動畫面跟讀。
- HTTP TTS engine 已接進 `ReaderPage` 主線。
- 跨章無縫朗讀一定完整接線。

## 自動翻頁

目前自動翻頁是 timer 驅動：

- 啟動後隱藏控制列。
- 預設每 8 秒呼叫 `runtime.moveToNextPage()`。
- 無法前進時停止。

它目前不提供獨立的 scroll 動畫體驗，只推進 runtime page window。

## 書籤

書籤以目前 visible location 建立，寫入 `bookmarks` table。欄位包含書籍、章節 index、章節位置、章節名稱與摘錄內容。

## 換源

目前有兩條 UI flow：

- 單章換源：抓候選 source 的目錄與正文，寫入該章 raw content，然後 reload。
- 整書 fallback 換源：遷移 book/source/chapter 資訊後，以 resume target 重新開 `ReaderPage`。

換源後應盡量保留原本的 `chapterIndex + charOffset` 語義，但實際落點仍受候選來源的章節匹配結果限制。

## 明確非目標

目前閱讀器不承諾：

- 第三種閱讀模式。
- manga/image reader。
- RSS 閱讀 flow。
- Android-only 工具頁照搬。
- 以 page index 作 durable progress。
- 未接線 runtime 旁支的 UI 行為。

## 驗證基線

一般 reader 修改：

```bash
flutter analyze
flutter test test/features/reader
```

若修改書源 JS、規則解析或 Linux 測試需要 QuickJS shared library，可使用：

```bash
tool/flutter_test_with_quickjs.sh test/features/reader
```

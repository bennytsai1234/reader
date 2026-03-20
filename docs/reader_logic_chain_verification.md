# 閱讀器核心邏輯鏈驗證報告

> 驗證日期：2026-03-19
> 涵蓋範圍：章節預載、合併、位置恢復、分頁引擎、翻頁模式、TTS 自動翻頁

---

## 目錄

1. [架構總覽](#1-架構總覽)
2. [邏輯鏈 A：章節預載與合併](#2-邏輯鏈-a章節預載與合併)
3. [邏輯鏈 B：位置恢復（開書 / 目錄跳轉）](#3-邏輯鏈-b位置恢復開書--目錄跳轉)
4. [邏輯鏈 C：分頁引擎](#4-邏輯鏈-c分頁引擎)
5. [邏輯鏈 D：翻頁模式（滾動 / 平移）](#5-邏輯鏈-d翻頁模式滾動--平移)
6. [邏輯鏈 E：進度儲存](#6-邏輯鏈-e進度儲存)
7. [邏輯鏈 F：TTS 朗讀與跨章節銜接](#7-邏輯鏈-ftts-朗讀與跨章節銜接)
8. [邏輯鏈 G：自動翻頁](#8-邏輯鏈-g自動翻頁)
9. [級聯載入防護系統](#9-級聯載入防護系統)
10. [已發現並修復的 Bug](#10-已發現並修復的-bug)
11. [邊緣情況驗證矩陣](#11-邊緣情況驗證矩陣)
12. [已知限制與取捨](#12-已知限制與取捨)

---

## 1. 架構總覽

### Mixin 組合鏈

```
ReaderProviderBase          ← DAO、基礎狀態（pages、chapterCache、pivotChapterIndex…）
  └── ReaderSettingsMixin   ← 字體/行距/主題等設定（SharedPreferences 讀寫）
        └── ReaderContentMixin  ← 章節加載、分頁、預載、合併
              └── ReaderProgressMixin  ← 進度儲存/恢復、字元偏移量計算
                    └── ReaderTtsMixin  ← TTS 朗讀、高亮追蹤、章節預取
                          └── ReaderAutoPageMixin  ← 自動翻頁計時器
                                └── ReaderProvider  ← 組合入口，_init() 串接所有初始化
```

### 核心資料結構

| 結構 | 說明 | 生命週期 |
|------|------|----------|
| `pages: List<TextPage>` | 當前可見的所有分頁（可跨章節合併） | 隨合併/trim/重新分頁動態變化 |
| `chapterCache: Map<int, List<TextPage>>` | 已分頁的章節快取 | 最多 5 章（由 `_trimPagesWindow` 控制） |
| `chapterContentCache: Map<int, String>` | 原始章節文字快取 | 最多 15 章（距離驅逐法） |
| `pivotChapterIndex` | CustomScrollView 雙向滾動的中心錨點 | 非合併載入時重置 |

### 座標系統

- **chapterPosition**：每行文字在其所屬章節中的字元偏移量（從 0 開始，每章獨立）
- **virtualY**：滾動模式的絕對像素座標 = `scrollController.pixels + pastExtent`
- **pastExtent**：pivot 之前所有頁面的累計高度

---

## 2. 邏輯鏈 A：章節預載與合併

### 2.1 觸發路徑

#### 滾動模式 (PageAnim.scroll)

```
用戶滾動 → ScrollController.listener → _handleScroll()
  ├── 接近頂部 (pixels ≤ minScroll + 500)
  │     → 四層防護檢查通過 → provider.prevChapter()
  └── 接近底部 (pixels ≥ maxScroll - 1500)
        → 四層防護檢查通過 → provider.nextChapter()
```

#### 平移模式 (PageAnim.slide)

```
用戶翻頁 → PageView.onPageChanged(i)
  ├── i ≥ pages.length - 2 → provider.nextChapter()
  └── i ≤ 1
        ├── i == 0 → provider.prevChapter(fromEnd: true)   // 跳到上一章末頁
        └── i == 1 → provider.prevChapter(fromEnd: false)  // 背景預載不跳轉
```

### 2.2 loadChapter 完整流程

```
loadChapter(i, fromEnd)
  │
  ├── 快取命中 → _performChapterTransition() → _preloadNeighborChaptersSilently()
  │
  ├── 靜默預載中 → 等待 Completer → 快取命中路徑
  │
  └── 需網路載入
        → fetchChapterData(i)      // 爬取 + ContentProcessor
        → _paginateInternal(i)      // ChapterProvider.paginate()
        → chapterCache[i] = newPages
        → _performChapterTransition()
        → _preloadNeighborChaptersSilently()
```

### 2.3 _performChapterTransition 合併邏輯

#### 合併路徑 (shouldMerge = true, !alreadyExists)

**向下合併 (isMovingDown = true)：**
```
1. currentChapterIndex = targetIndex（暫時，供 trim 計算距離）
2. pages = [...pages, ...newPages]   // 追加到尾部
3. _trimPagesWindow()                // 若超過 5 章，距離驅逐
```

**向上合併 (isMovingDown = false)：**
```
1. originalChapterIndex = currentChapterIndex（保存原值）
2. currentChapterIndex = targetIndex（暫時）
3. pages = [...newPages, ...pages]   // 插入到前方
4. _trimPagesWindow()
5. 滾動模式：currentChapterIndex = originalChapterIndex（恢復）
   → 讓 _updateScrollPageIndex 在後續滾動事件中自然更新
6. 平移模式：
   ├── fromEnd = true  → currentPageIndex = 上一章最後頁
   └── fromEnd = false → currentPageIndex += addedPageCount（補償前方插入）
   → jumpPageController.add(currentPageIndex)
```

#### 非合併路徑 (跳轉到非鄰近章節)

```
1. pages = newPages（完全替換）
2. currentChapterIndex = targetIndex
3. pivotChapterIndex = targetIndex（重置錨點）
4. 若非恢復中：jumpToPositionFn(pageIndex: targetPage)
```

### 2.4 _trimPagesWindow 驅逐策略

```
while (已載入章節數 > 5):
  1. 計算第一章和最後章到 currentChapterIndex 的距離
  2. 驅逐距離更遠的那端
  3. 保護 pivotChapterIndex（僅當確實有 pastContent 時）
  4. 若驅逐前方章節：currentPageIndex -= removedCount（補償索引）
  5. 清除 chapterCache[toRemove]（保留 chapterContentCache 不刪，回翻免重新下載）
```

### 2.5 靜默預載策略

```
_preloadNeighborChaptersSilently()
  → 向後預載 2 章：lastIdx+1, lastIdx+2
  → 向前預載 2 章：firstIdx-1, firstIdx-2
  → 按距離 currentChapterIndex 排序（近→遠）
  → 依序執行 _preloadChapterSilently()（不觸發 UI 轉圈）
```

### 2.6 驗證結論

| 場景 | 預期行為 | 驗證結果 |
|------|----------|----------|
| 滾動模式向下合併 | 頁面追加到尾部，視覺位置不動 | **正確** |
| 滾動模式向上合併 | 頁面插入前方，currentChapterIndex 恢復原值 | **正確**（修改 5 修復） |
| 平移模式向下合併 | 頁面追加，pageIndex 不變 | **正確** |
| 平移模式向上合併 (fromEnd=true) | 跳到上一章末頁 | **正確** |
| 平移模式向上合併 (fromEnd=false) | 補償 pageIndex += addedPageCount | **正確** |
| 非鄰近跳轉 | 完全替換 pages，重置 pivot | **正確** |
| Trim 驅逐 | 距離最遠的章節被移除，pageIndex 補償 | **正確** |

---

## 3. 邏輯鏈 B：位置恢復（開書 / 目錄跳轉）

### 3.1 開書恢復流程

```
ReaderProvider._init()
  → loadSettings()
  → _loadChapters()
  → _loadSource()
  → isRestoring = true
  → pendingRestorePos = initialCharOffset
  → _wireUpMixins()
  → loadChapter(currentChapterIndex)
  → applyPendingRestore()
```

### 3.2 applyPendingRestore 分支

**滾動模式 (Zero-Jump)：**
```
1. initialTargetY = calcScrollOffsetForCharOffset(pos)
2. isRestoring = false
   → ReaderViewBuilder.build() 用 initialTargetY 建構 ScrollController
   → 首次渲染即在正確位置，無跳閃
```

**分頁模式：**
```
1. jumpToPosition(charOffset: pos, isRestoringJump: true)
2. → findPageIndexByCharOffset(charOffset)   // charOffset → pageIndex
3. → jumpPageController.add(targetPage)       // 命令 PageView 跳頁
4. → ReaderViewBuilder 收到 jumpPage 後設 isRestoring = false
```

### 3.3 setViewSize 的恢復時序

```
setViewSize(size)
  ├── 首次 (viewSize == null)
  │     → viewSize = size
  │     → 若 chapterContentCache 已有 → doPaginate().then(applyPendingRestore)
  │     → 否則 → loadChapter()（loadChapter 完成後 _init 會呼叫 applyPendingRestore）
  │
  └── 後續（尺寸變化 > 10x20 門檻）
        → doPaginate()（使用 charOffset 保存/恢復位置）
```

### 3.4 驗證結論

| 場景 | 預期行為 | 驗證結果 |
|------|----------|----------|
| 滾動模式開書恢復 | ScrollController 初始偏移直接到位 | **正確** |
| 分頁模式開書恢復 | PageView 跳到對應頁碼 | **正確** |
| viewSize 延遲就緒 | pendingRestorePos 等到分頁完成後恢復 | **正確** |
| 裝置旋轉 | doPaginate 重新分頁，charOffset 保位 | **正確**（但會丟失鄰近章節） |

---

## 4. 邏輯鏈 C：分頁引擎

### 4.1 ChapterProvider.paginate 流程

```
輸入：content, chapter, viewSize, textStyles
  │
  ├── 1. 處理標題
  │     → TextPainter.layout → computeLineMetrics
  │     → 每行建立 TextLine(isTitle: true)
  │     → chapterPos += title.length
  │
  ├── 2. 處理段落
  │     → content.split('\n')
  │     → 每段加上 textIndent 縮排
  │     → 逐行排版：TextPainter.getLineBoundary
  │     → 避頭/避尾點處理
  │     → chapterPos 追蹤字元偏移（扣除縮排字元）
  │     → 行高 = fontSize × lineHeight
  │     → 超出頁高 → addPage()
  │
  └── 3. 輸出
        → List<TextPage>（每頁含 pageSize = 總頁數）
```

### 4.2 chapterPosition 計算規則

```
chapterPos = 0
  + title.length                                    // 標題
  + Σ(每段文字長度 - 縮排字元數)                     // 段落內容
  + Σ(1 per paragraph)                              // 段落換行符
```

**關鍵屬性**：
- `chapterPosition` 在同一章節內單調遞增
- 跨章節時，chapterPosition 各自從 0 開始
- 是進度儲存 (`durChapterPos`)、TTS 高亮、位置恢復的共同基礎

### 4.3 doPaginate (重新分頁) 流程

```
doPaginate(fromEnd)
  → 保存 oldCharOffset = getCharOffsetForScrollYFn(lastKnownScrollY)
  → ChapterProvider.paginate()
  → chapterCache[currentChapterIndex] = pages（替換為單章節頁面）
  → fromEnd ? jumpToPosition(pageIndex: lastPage)
             : jumpToPosition(charOffset: oldCharOffset)
```

### 4.4 驗證結論

| 場景 | 預期行為 | 驗證結果 |
|------|----------|----------|
| 正常分頁 | 文字完整排版，不丟字不重複 | **正確** |
| 避頭/避尾點 | 標點不出現在行首/行尾 | **正確** |
| 縮排計算 | chapterPosition 不含縮排字元 | **正確** |
| 每 10 段 yield | 不凍結 UI | **正確** |
| 重新分頁位置恢復 | charOffset 保持視覺位置 | **正確** |

---

## 5. 邏輯鏈 D：翻頁模式（滾動 / 平移）

### 5.1 滾動模式 (PageAnim.scroll)

**Widget 結構：**
```
CustomScrollView(center: _centerKey)
  ├── SliverList (past)     ← pastPages（pivot 之前），反向渲染
  └── SliverList (future)   ← futurePages（pivot 及之後），_centerKey 標記
```

**座標系統：**
```
                    ┌────────────────────┐
                    │   pastPages (反向)  │  ← minScrollExtent（負值方向）
                    │   chapter N-2       │
                    │   chapter N-1       │
  scrollOffset = 0 ├════════════════════┤  ← center key (pivot)
                    │   futurePages       │
                    │   chapter N         │
                    │   chapter N+1       │
                    └────────────────────┘  ← maxScrollExtent

  virtualY = scrollOffset + pastExtent（轉換為從全部內容頂部開始的絕對像素）
```

**滾動事件處理：**
```
_handleScroll()
  → 計算 virtualY
  → _updateScrollPageIndex(virtualY)   // 更新 currentPageIndex + currentChapterIndex
  → updateScrollOffset(virtualY)       // 更新 lastScrollY + 進度追蹤
  → isRestoring? → return
  → 速度追蹤更新
  → _suppressScrollCheck? → return
  → velocity > 3.0 px/ms? → return
  → 邊界檢測（上方/下方）
```

### 5.2 平移模式 (PageAnim.slide)

**Widget 結構：**
```
PageView.builder(itemCount: pages.length)
  → onPageChanged(i)
     → p.onPageChanged(i)        // 更新狀態 + 儲存進度
     → 邊界觸發 prevChapter/nextChapter
```

**翻頁跳轉：**
```
jumpPageController.stream → PageView.jumpToPage()
  ← 來源：位置恢復、章節合併後補償、TTS 翻頁
```

### 5.3 驗證結論

| 場景 | 預期行為 | 驗證結果 |
|------|----------|----------|
| 滾動模式 pastPages 反向渲染 | 頁面視覺順序正確 | **正確** |
| 滾動模式 virtualY 計算 | 加上 pastExtent 得到絕對座標 | **正確** |
| 平移模式 onPageChanged | 觸發狀態更新 + 預載 | **正確** |
| 滾動模式 showHead (2px) | 第一章無 head，後續章有 | **正確** |
| 模式切換 | 由 AnimatedSwitcher 處理過渡 | **正確** |

---

## 6. 邏輯鏈 E：進度儲存

### 6.1 儲存格式

```
durChapterIndex: int   ← 章節索引
durChapterPos: int     ← 字元偏移量 (chapterPosition)
durChapterTitle: String
```

### 6.2 觸發時機

| 觸發者 | 模式 | 條件 |
|--------|------|------|
| `updateScrollOffset` | 滾動 | 字元差 > 600 立即存；其餘 debounce 500ms |
| `ReaderProvider.onPageChanged` | 平移 | 每次翻頁（非恢復期間） |
| `dispose` | 全部 | 退出閱讀器時 |
| `didChangeAppLifecycleState` | 全部 | App 進入背景 |

### 6.3 進度計算

**滾動模式：**
```
getCharOffsetForScrollY(lastScrollY)
  → 遍歷所有頁面，找到 lineAbsBottom > scrollY 的第一個文字行
  → 返回該行的 chapterPosition
```

**分頁模式：**
```
getCharOffsetForPage(pageIndex)
  → 返回該頁第一個非圖片行的 chapterPosition
```

### 6.4 驗證結論

| 場景 | 預期行為 | 驗證結果 |
|------|----------|----------|
| 滾動模式精確儲存 | 視窗頂端行的 charOffset | **正確**（修復後） |
| 分頁模式儲存 | 當前頁首行的 charOffset | **正確** |
| 章節邊界過渡儲存 | currentChapterIndex 與 charOffset 一致 | **已修復**（Bug 1） |
| TTS 進度儲存 | 使用 _ttsStart 而非滾動位置 | **正確** |
| App 背景時儲存 | 立即寫 DB | **正確** |

---

## 7. 邏輯鏈 F：TTS 朗讀與跨章節銜接

### 7.1 TTS 啟動流程

```
toggleTts()
  → _startTts()
     → 決定起始頁/行（滾動模式用視口頂端行）
     → 收集 targetChapterIndex 從 startCharPos 到章末的所有文字行
     → prepareTtsData() → 建構 TTS 文字 + offsetMap
     → TTSService().speak(text)
     → _prefetchNextChapterTts()
     → 設定錨點：_ttsAnchorChapterIdx, _ttsAnchorEndCharPos
```

### 7.2 高亮追蹤

```
_onTtsProgressUpdate()
  → TTSService().currentWordStart → rawStart
  → 查表 _ttsTextOffsetMap → chapterBase（章節字元位置）
  → 快取命中？→ return（避免全頁掃描）
  → 全頁掃描：找到 chapterBase 所在的段落 → 整段高亮
  → 設定 _ttsStart, _ttsEnd
  → 平移模式：自動翻到對應頁
```

### 7.3 章節邊界銜接

```
_onTtsComplete()  （整章朗讀完成）
  ├── _ttsCancelled? → return
  ├── _ttsCompleteProcessing? → return（防重入）
  │
  → 取出預取數據（_prefetchedChapterTtsText）
  → nextChapter().then(() {
       ├── 有預取數據 → 直接 speak()（零停頓銜接）
       └── 無預取數據 → _startTts()（需等待分頁）
     })
```

### 7.4 TTS 跨章節安全機制

- `_ttsChapterIndex`：過濾高亮，確保不會在多章節合併頁面中跨章節重複高亮
- `_ttsCancelled`：stopTts() 後設為 true，阻止 pending 的 then() 回調繼續
- `_ttsCompleteProcessing`：防止 iOS flutter_tts 重複 didFinish 導致重入

### 7.5 驗證結論

| 場景 | 預期行為 | 驗證結果 |
|------|----------|----------|
| 整章朗讀 + 段落高亮 | 高亮跟隨朗讀進度，以段落為單位 | **正確** |
| 章節切換預取 | 下一章 TTS 文字預先準備 | **正確** |
| 零停頓銜接 | 使用預取數據直接 speak() | **正確** |
| 停止 TTS 後不繼續 | _ttsCancelled 阻止 then() | **正確** |
| 重複 didFinish 防護 | _ttsCompleteProcessing 過濾 | **已修復**（Bug 2） |
| 滾動模式 TTS 視口追蹤 | _scrollToTtsHighlight 自動捲動 | **正確** |

---

## 8. 邏輯鏈 G：自動翻頁

### 8.1 運作機制

**分頁模式：**
```
Timer.periodic(16ms)
  → autoPageProgressNotifier += delta
  → progress >= 1.0 → nextPage()（跨章節自動觸發 nextChapter）
```

**滾動模式：**
```
Ticker (_autoScrollTicker)
  → 每幀 jumpTo(currentScroll + tickDelta)
  → 到達 maxExtent → provider.nextChapter()
```

### 8.2 互斥機制

- TTS 播放時自動翻頁暫停（`TTSService().isPlaying` 檢查）
- 自動翻頁啟動時停止 TTS（`onTtsStartCallback`）
- 選單開啟時暫停（`pauseAutoPage`），關閉時恢復（`resumeAutoPage`）

### 8.3 驗證結論

| 場景 | 預期行為 | 驗證結果 |
|------|----------|----------|
| 分頁模式自動翻頁 | 定時翻頁，到章末自動載入下一章 | **正確** |
| 滾動模式自動翻頁 | 像素級平滑滾動，到底觸發載入 | **正確** |
| TTS 與自動翻頁互斥 | 不會同時運作 | **正確** |
| 選單暫停/恢復 | 選單開啟暫停，關閉恢復 | **正確** |

---

## 9. 級聯載入防護系統

### 9.1 四層防護架構

```
_handleScroll()
  │
  ├── Layer 1: In-flight Guard
  │     _isFetchingPrev / _isFetchingNext
  │     → 防止同時觸發多個同方向載入
  │
  ├── Layer 2: Layout Suppression
  │     _suppressScrollCheck = true
  │     → 觸發載入時設 true → 完成後延遲兩幀解除
  │     → 給 Flutter layout engine 足夠時間重新計算 SliverList extent
  │
  ├── Layer 3: Cooldown + Distance Gate
  │     _prevLoadCompletedAt + _scrollPosAtLastPrevLoad
  │     → 600ms 冷卻期：上次載入完成後不立即重觸
  │     → 300px 距離門檻：使用者必須離開邊界再回來才能觸發
  │
  └── Layer 4: Velocity Suppression
        velocity > 3.0 px/ms → return
        → 快速 fling 時只滾動不載入，減速後才觸發
```

### 9.2 防護生效時序

```
t=0ms:    用戶快速向上 fling
t=0-50ms: velocity > 3.0 → Layer 4 攔截（不觸發載入）
t=50ms:   速度降低 → 進入邊界檢測
          → Layer 1: _isFetchingPrev = false ✓
          → Layer 3: 無歷史載入 ✓
          → 觸發 prevChapter()
          → Layer 1: _isFetchingPrev = true
          → Layer 2: _suppressScrollCheck = true
t=100ms:  新頁面插入，layout 重算中
          → Layer 2 攔截所有邊界檢測
t=200ms:  prevChapter 完成
          → postFrameCallback: _isFetchingPrev = false
          → _prevLoadCompletedAt = now
          → _scrollPosAtLastPrevLoad = currentScroll
t=230ms:  第二個 postFrameCallback: _suppressScrollCheck = false
t=231ms:  _handleScroll 恢復運作
          → Layer 3: 600ms 冷卻未過 → 攔截
t=800ms:  冷卻期結束
          → Layer 3: 距離檢查 → 滾動距離 < 300px → 攔截
t=???:    用戶主動向下滾動 300px 再回到頂部
          → 所有 Layer 通過 → 允許新的載入
```

---

## 10. 已發現並修復的 Bug

### Bug 1 (Medium): 進度儲存使用過期的 currentChapterIndex

**檔案**: `reader_view_builder.dart` `_handleScroll()`

**問題**: `updateScrollOffset()` 在 `_updateScrollPageIndex()` 之前呼叫。在章節邊界過渡時，`updateScrollOffset` 內的 `crossThreshold` 路徑會立即呼叫 `saveProgress(currentChapterIndex, ...)`，但 `currentChapterIndex` 尚未被 `_updateScrollPageIndex` 更新到新章節。

**後果**: 章節 B 的 charOffset 被存到章節 A 下，恢復時回到錯誤位置。

**修復**: 交換呼叫順序：先 `_updateScrollPageIndex`，再 `updateScrollOffset`。

### Bug 2 (Medium): TTS 完成防重入旗標過早失效

**檔案**: `reader_tts_mixin.dart` `_onTtsComplete()`

**問題**: `_ttsCompleteProcessing = false` 在 `finally` 區塊中，但 `finally` 在 `nextChapter().then()` 之前就執行（因為 `.then()` 是異步的）。

**後果**: iOS flutter_tts 的重複 `didFinish` 事件穿過防護，可能導致同一章節切換觸發兩次、重複 speak 或狀態混亂。

**修復**: 將 `_ttsCompleteProcessing = false` 移入 `.then()` 和 `.catchError()` 內部，確保異步操作完成後才重置。

### Bug 3 (Minor): 速度追蹤在抑制期間不更新

**檔案**: `reader_view_builder.dart` `_handleScroll()`

**問題**: 速度追蹤變數的更新位於 `_suppressScrollCheck` 檢查之後。抑制期間跳過更新，解除後第一次計算基於過期數據。

**後果**: 可能誤判為低速（因 dt 很大但 distance 也大），在本應抑制時錯誤觸發載入。

**修復**: 將速度追蹤更新移到 `_suppressScrollCheck` 檢查之前。

---

## 11. 邊緣情況驗證矩陣

### 章節邊界

| 邊緣情況 | 檢測點 | 結果 |
|----------|--------|------|
| 第一章（chapter 0）向上滾動 | `firstPage.chapterIndex > 0` → false | **安全**：不觸發載入 |
| 最後一章向下滾動 | `lastPage.chapterIndex < chapters.length - 1` → false | **安全**：不觸發載入 |
| 單頁章節（很短的章節） | 平移模式 i=0 同時 i>=length-2 | **安全**：有 `_isFetchingPrev`/`_isFetchingNext` 各自獨立 |
| 空章節（content 為空） | paginate 返回空 pages → loadChapter 不存快取 | **安全**：等 viewSize 就緒後重試 |
| 章節載入失敗 | fetchChapterData catch → 錯誤訊息作為內容 | **可接受**：使用者看到錯誤提示 |

### 並發與時序

| 邊緣情況 | 檢測點 | 結果 |
|----------|--------|------|
| 同一章節重複請求 | `loadingChapters.contains(i)` → return | **安全** |
| 靜默預載 + 主動載入同一章 | Completer 協調，等待完成後走快取路徑 | **安全** |
| 快速連續目錄跳轉 | 非合併路徑替換 pages，最後完成的生效 | **可接受** |
| dispose 期間異步操作 | 所有 await 後檢查 `isDisposed` | **安全** |
| viewSize 為 null 時分頁 | `_paginateInternal` 返回空列表 → 不存快取 | **安全** |

### 模式切換

| 邊緣情況 | 檢測點 | 結果 |
|----------|--------|------|
| 滾動↔平移切換 | `AnimatedSwitcher` + `_buildModeReader` 分支 | **安全**：重建 Widget 樹 |
| 切換時 TTS 正在播放 | TTS 狀態獨立於翻頁模式，繼續播放 | **安全** |
| 切換時自動翻頁中 | `_stopScrollAutoPage()` / `_startAutoPage()` 自適應 | **安全** |

### 字體/設定變更

| 邊緣情況 | 檢測點 | 結果 |
|----------|--------|------|
| 多章節合併中改字體 | `chapterCache.clear()` + `doPaginate()` → pages 退化為單章 | **可接受**：丟失鄰近章節，需重新滾動載入 |
| 繁簡轉換變更 | `clearReaderCache()` 清除所有快取 + 重新載入 | **正確** |

---

## 12. 已知限制與取捨

### L1: doPaginate 退化為單章節

**現象**：字體大小/行距等設定變更時，`doPaginate()` 用 `ChapterProvider.paginate()` 重新排版當前章節，`pages` 被替換為單章頁面。已合併的鄰近章節丟失。

**影響**：使用者需重新滾動到邊界才能觸發鄰近章節重新載入。

**接受理由**：設定變更頻率低；若要支持多章重新排版，需遍歷 chapterContentCache 中所有章節重新分頁，CPU 開銷過大。

### L2: 滑動窗口最多 5 章

**現象**：超過 5 章的內容被驅逐（chapterCache 移除），回翻需重新分頁（但 chapterContentCache 保留原始文字，不需重新下載）。

**接受理由**：記憶體限制。每章分頁結果包含大量 TextLine 物件，5 章已是合理上限。

### L3: chapterPosition 跨章節不連續

**現象**：`chapterPosition` 在每個章節內從 0 開始。這意味著 `findPageIndexByCharOffset` 在多章合併的 pages 中，如果 charOffset 較小，可能匹配到後方章節的開頭頁。

**影響範圍**：`findPageIndexByCharOffset` 僅在分頁模式的 `jumpToPosition` 中使用，而此時通常只有單章或恢復場景。多章合併場景使用 `jumpPageController` 直接跳頁，不經過此函式。

**風險等級**：低。但未來若擴展使用場景，需加入 chapterIndex 過濾。

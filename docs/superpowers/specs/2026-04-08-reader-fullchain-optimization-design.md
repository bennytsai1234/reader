# Reader 全鏈路功能性與邊緣案例優化設計文件

**日期：** 2026-04-08  
**範疇：** 閱讀器核心路徑——從「開啟一本書」到「持續閱讀」  
**方法：** 全鏈路順序推進（Top-down Chain）  
**產出：** 問題清單 + 直接修復 + 測試驗證  

---

## 一、背景與目標

本專案為 Flutter/Dart 中文小說閱讀器（Legado Reader），支援：
- 本地書籍（TXT/EPUB/PDF/MOBI/UMD）
- 網路書源（Legado 3.0 規則引擎）
- 滾動（Scroll）與翻頁（Slide）兩種閱讀模式
- TTS 朗讀與進度持久化

核心閱讀路徑涉及多個模組的協作，模組邊界存在競態條件、邊緣案例未守護、性能瓶頸等潛在問題。本次優化目標：

1. **功能性加固**：修復所有可能導致進度丟失、狀態不一致、崩潰的邏輯缺陷
2. **邊緣案例覆蓋**：確保極端輸入（空章節、超長文字、網路中斷等）有正確處理
3. **性能提升**：消除不必要的重建、過度計算、記憶體洩漏

---

## 二、全鏈路節點拆解

```
[N1] 開書初始化
  BookShelf → ReadBookController.open()
  ↓
[N2] 章節內容抓取
  ChapterContentManager → fetch → 網路/本地 parser
  ↓
[N3] 文字分頁計算
  raw text → TextPage[] (含 charOffset 映射)
  ↓
[N4] 進度恢復定位
  RestoreCoordinator → charOffset → page/scroll position
  ↓
[N5] 畫面顯示與導航
  ScrollMode / SlideMode → 使用者互動 → 翻頁/跳章
  ↓
[N6] 進度持久化
  ReaderProgressStore → debounce write → SQLite
  ↓
[N7] TTS 同步跟隨
  ReadAloudController → TtsFollowCoordinator → scroll sync
```

---

## 三、各節點分析重點與已知風險

### N1 — 開書初始化

**關鍵路徑：** `ReadBookController.open()` → 狀態重置 → 初始化子協調器

**風險點：**
- 重複呼叫 `open()` 前未確保前次 `dispose()` 完成（異步競態）
- 舊書的殘留狀態未完全清除就開新書
- 子協調器初始化順序依賴未明確

**修復策略：**
- 加入 `_isOpening` guard flag，防止重入
- `dispose()` 改為 awaitable，open 前 await 完成
- 明確定義初始化順序，記錄依賴關係

---

### N2 — 章節內容抓取

**關鍵路徑：** `ChapterContentManager.ensureChapterReady()` → fetch → parser → cache

**風險點：**
- 同一章節可能被並發觸發多次抓取（無 dedup lock）
- 網路失敗後重試無上限，可能無限循環
- 空內容（0 字元）未攔截，流入分頁計算導致異常
- 本地 TXT 超大章節（>50KB）切割邏輯的邊界處理

**修復策略：**
- 加入 per-chapter inflight request 追蹤 Map，dedup 並發抓取
- 設定最大重試次數（建議 3 次），超出後標記為錯誤狀態
- 抓取完成後立即驗證 content 非空，否則插入佔位錯誤頁
- 審查 TxtParser chunk 邊界是否保留完整行

---

### N3 — 文字分頁計算

**關鍵路徑：** `ChapterProvider` → 測量文字 → 生成 `TextPage[]` → 建立 charOffset 映射

**風險點：**
- 字體尚未載入完成前觸發計算，得到錯誤的測量結果
- 計算結果產生零高度頁（空頁），導致無限循環翻頁
- `charOffset` 邊界差 1（off-by-one），造成最後一個字元定位錯誤
- 設定變更（字體大小、行距）後，重新計算未正確觸發

**修復策略：**
- 分頁計算前確保字體已載入（await font loading future）
- 每頁生成後斷言 `pageHeight > 0`，否則強制設最小高度
- 統一 charOffset 的區間語意（左閉右開 vs 左閉右閉），加單元測試驗證
- 設定變更時確保完整清除 pagination cache 並重新計算

---

### N4 — 進度恢復定位

**關鍵路徑：** `ReaderRestoreCoordinator` → 等待章節 ready → charOffset → page index → 滾動/定位

**風險點：**
- Token 競態：新 restore 請求到來時，舊 token 的 callback 仍可能執行
- `charOffset` 超出章節實際長度（資料庫儲存的進度 > 當前內容長度）
- 目標章節尚未 paginate 完成就嘗試定位，得到錯誤頁碼
- 恢復失敗時無 fallback（直接卡在 loading 狀態）

**修復策略：**
- 強化 token cancellation 檢查，所有異步 callback 入口均驗證 token 有效
- `charOffset = min(charOffset, chapter.content.length - 1)`，clamp 超界值
- 確保定位前 `await onChapterReady`，而非僅檢查快取存在
- 恢復失敗時 fallback 至章節首頁，並記錄 warning log

---

### N5 — 畫面顯示與導航

**關鍵路徑：** 使用者互動 → `ReaderNavigationController` → command queue → 執行翻頁/跳章

**風險點：**
- 快速連續點擊（<100ms）產生多個跳章指令，command guard 可能未全部攔截
- 最後一章最後一頁繼續往後翻，狀態異常
- 第一章第一頁繼續往前翻，狀態異常
- Slide 模式與 Scroll 模式切換時，page index 換算邏輯可能不一致

**修復策略：**
- Command guard 加入防抖（debounce 200ms）或 mutex，確保同時只有一個導航指令執行
- 邊界頁面的「繼續翻頁」改為靜默忽略 + 可選 haptic feedback
- 模式切換時，統一從 charOffset 重新換算目標位置，而非直接用 page index

---

### N6 — 進度持久化

**關鍵路徑：** `ReaderProgressStore` → debounce（500ms）→ DAO write → SQLite

**風險點：**
- App 在 debounce 等待期間被系統 kill，最後一次進度丟失
- 寫入 SQLite 失敗時無錯誤日誌，靜默失敗
- 頻繁滾動時 debounce 可能延遲過長，造成積壓

**修復策略：**
- 監聽 `AppLifecycleState.paused` / `detached`，在 app 進入背景前強制 flush（跳過 debounce）
- 資料庫寫入加 try-catch，失敗時 `logger.warning()`
- 考慮 debounce 時間是否合理（滾動模式可適度縮短）

---

### N7 — TTS 同步跟隨

**關鍵路徑：** `ReadAloudController` → 朗讀位置 → `ReaderTtsFollowCoordinator` → 調整 scroll 位置

**風險點：**
- TTS 播到章節末尾時，scroll 嘗試定位到不存在的位置
- 切章時前一章的高亮標記未清除，與新章內容重疊
- TTS 速度很快時，scroll 跟隨觸發過於頻繁（每字更新）

**修復策略：**
- 章節末尾邊界守衛：`scrollOffset = min(offset, maxScrollExtent)`
- 切章事件觸發時，先清除所有高亮再建立新章高亮
- TTS 跟隨加入節流（throttle 250ms），避免過度 scroll 更新

---

## 四、驗證策略

### 靜態驗證（每次修復後必跑）

```bash
flutter analyze
flutter test
```

### 針對性測試

| 節點 | 相關測試檔案 |
|------|------------|
| N1 | `read_book_controller_test.dart` |
| N2 | `chapter_content_manager_test.dart` |
| N3 | `text_page_serialization_test.dart` |
| N4 | `reader_restore_coordinator_test.dart`（若不存在則新建） |
| N5 | `reader_navigation_controller_test.dart` |
| N6 | `reader_progress_store_test.dart` |
| N7 | TTS 相關邏輯測試（視覆蓋率補充） |

### 邊緣案例驗證清單

- [ ] 空章節（0 字元內容）
- [ ] 超長章節（>100KB 文字）
- [ ] 特殊字元（Emoji、全形符號、混排）
- [ ] 快速連續翻頁（<100ms 間隔）
- [ ] 網路中斷時切章
- [ ] App 切背景再回來後進度正確
- [ ] TTS 播到最後一章最後一頁
- [ ] 字體大小變更後重新分頁
- [ ] 資料庫進度記錄 charOffset 超出當前章節長度

---

## 五、實施順序

按鏈路順序逐節點推進：N1 → N2 → N3 → N4 → N5 → N6 → N7

每個節點完成步驟：
1. 讀取相關原始碼，確認實際實作（路徑 + 行號）
2. 列出具體問題
3. 直接修改程式碼
4. 執行 `flutter analyze` + 相關測試
5. 確認後進入下一節點

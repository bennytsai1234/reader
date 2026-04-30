# Reader V2 垂直滾動流暢度技術優化方案

## 1. 目標

本文件聚焦 `lib/features/reader_v2` 的「垂直滾動模式」效能與穩定性，特別是：

- 章節切換邊界（上一章/下一章銜接）
- 快速連續翻動（連續 fling / 連續命令 / 手勢與自動翻頁併發）
- 降低使用者看到 `載入中` 的頻率

## 2. 不變約束

以下設計邊界保持不變：

- `reader_v2` 仍是新的主線閱讀器模型。
- 不引入可持久化 page snapshot，維持 in-memory cache。
- 不新增 speculative restore fallback 分支。
- 水平 slide 路徑與垂直 scroll 路徑分離，不互相硬套模型。

## 3. 現況瓶頸地圖

### 3.1 高頻狀態回寫造成重建壓力

- Scroll viewport 在滾動過程中高頻回報 visible location。
- Runtime 每次可見位置改變都可能觸發 `notifyListeners()`。
- 上層 `ReaderV2Page` 目前採「收到變動就立即 setState」策略，易造成高頻重建。

影響：滾動中掉幀、UI 主線程抖動。

### 3.2 邊界未就緒時視覺切換生硬

- 章節窗口尚未就緒時，Scroll viewport 傾向直接切到全屏 loading。
- 造成可感知的畫面閃斷，放大 `載入中` 體感。

影響：章節邊界觀感差，快速滾動時尤甚。

### 3.3 settle 即時寫入過密

- Scroll settle 後預設即時 progress flush。
- 連續短距離操作時寫入頻率偏高。

影響：I/O 壓力增加，干擾手勢後續流暢度。

### 3.4 章節窗口與預載策略仍可再前置

- 現有策略已在邊界預載上改善，但高速場景仍可能撞到未就緒章節。

影響：邊界停頓與 placeholder 出現率仍有下降空間。

## 4. 邊緣情況總表

1. 高速 fling 連續跨 2+ 章，前方 layout 未完成。
2. fling 尚未停下即反向拖動，窗口位移任務仍在進行。
3. 到章節尾端持續上推，scroll clamp 導致「卡住」體感。
4. 短章節密集切換，窗口頻繁重置。
5. 長章節下可見行定位成本放大。
6. 邊界章節載入失敗後，下一次翻動重試路徑是否平滑。
7. 章節未就緒時是否出現整屏 loading 閃斷。
8. 邊界來回抖動時的 cache thrash。
9. TTS 跟隨與手動滾動同時發生。
10. AutoPage tick 與手勢拖動競爭控制權。
11. 版式切換進行中仍收到翻頁命令。
12. app 進背景/離開頁面時 progress flush 與 restore 競態。

## 5. 分階段優化策略

### Phase P0（本次先落地）

#### P0-1. 高頻可見位置同步改為「可靜默」

- 在 Runtime 可見位置捕捉 API 增加 `notifyIfChanged` 控制。
- 滾動中的可見位置同步採「更新 state、但不 notify」模式。
- 只在必要節點（settle、跳章、模式切換）觸發可觀測通知。

預期效果：降低滾動中的全域通知風暴。

#### P0-2. 頁面重建合併（coalesced rebuild）

- `ReaderV2Page` 對 Host 通知改為「同 frame 最多一次 setState」。

預期效果：避免單 frame 多次重建。

#### P0-3. 章節未就緒時保留既有內容畫布

- Scroll 模式若仍有可見頁，優先顯示既有畫布並疊加 loading overlay。
- 僅在完全沒有可用頁時才顯示全屏 loading。

預期效果：降低 `載入中` 閃斷體感。

#### P0-4. Scroll settle 儲存走 debounce 路徑

- Scroll settle 時 `saveProgress(immediate: false)`。
- 生命週期與退出流程仍會 `flushProgress()` 做最終落盤。

預期效果：降低頻繁 I/O 對互動流暢度的干擾。

### Phase P1（下一輪）

- 速度感知預載（基於 fling 方向與速度動態擴大預載半徑）。
- 章節窗口淘汰策略加入 hysteresis/LRU，降低邊界 thrash。
- `ReaderV2ChapterView` 熱路徑查找改二分索引。

### Phase P2（觀測與自動回歸）

- 補齊 runtime/viewport 指標：frame time、layout 耗時、placeholder 次數。
- 對高速跨章與併發手勢建立穩定回歸測試集。

## 6. 驗收指標

- 滾動操作中 runtime 通知次數顯著下降（相同手勢序列下）。
- 章節邊界的全屏 loading 出現次數下降。
- 快速連續翻動時無明顯卡頓/閃斷。
- TTS follow、AutoPage、手動滾動功能保持可用。

## 7. 測試計畫

本次 P0 至少驗證：

- `reader_v2_runtime_test.dart`
- `reader_v2_viewport_test.dart`

新增測試方向：

- `captureVisibleLocation(notifyIfChanged: false)` 不應觸發 listener，但應更新可見位置。

## 8. 本次實作清單（Execution Log）

- [x] P0-1 高頻可見位置靜默同步
- [x] P0-2 ReaderV2Page 合併重建
- [x] P0-3 Scroll 未就緒時保留畫布 + loading overlay
- [x] P0-4 Scroll settle 儲存改 debounce
- [x] P1-1 速度感知方向預載（依 fling 速度擴大章節跨度）
- [x] P1-2 Cache soft-retain（LRU/hysteresis）降低邊界來回 thrash
- [x] P1-3 ChapterView 查找熱路徑改二分索引
- [x] 測試與驗證

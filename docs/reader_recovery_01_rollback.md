# Reader Recovery Option 1: Roll Back To 0.2.28

## 適用情境

只有在目前 `reader` 已經嚴重到無法交付，且需要很快恢復一個比較熟悉的閱讀體驗時，才應考慮退回 `reader-0.2.28`。

這是止血方案，不是長期方案。

## 優點

- 舊版 DB schemaVersion 是 10，對當時資料庫升級路徑比較完整。
- `durChapterIndex + durChapterPos` 與 `readerAnchorJson` 已經接進主流程。
- `flushNow()` 比新版完整，處理 scroll pending、TTS progress、read record、lifecycle。
- scroll restore 期間有 pending restore token、visible confirmation、local offset snapshot。
- 測試覆蓋包含 `read_book_controller_test`、`reader_runtime_flow_test`、`reader_viewport_runtime_test`、`scroll_runtime_executor_test` 等。
- `ReaderPage` 本身很薄，頁面層比較少直接承擔 runtime 邏輯。

## 缺點

- `ReadBookController` 約 2546 行，責任過重。
- provider/mixin/callback 網太密，修改成本高。
- content lifecycle、viewport command、session、progress、TTS、source switch 都在同一主物件附近交織。
- 舊版本來也不是穩定漂亮的 reader，只是某些行為比目前新版完整。
- 退回會丟掉新版已經建立的 `LayoutEngine`、`PageResolver`、`ReaderRuntime` 主線方向。
- 後續每次修 restore 或 viewport，都會回到舊 controller 的耦合問題。

## 如果真的要退回

退回不能只複製 `lib/features/reader`。至少要同步處理：

- `lib/core/models/book*`
- `lib/core/database/app_database.dart`
- `lib/core/database/tables/app_tables.dart`
- `lib/core/database/dao/book_dao.dart`
- reader content cache DAO / table
- source switch、backup/restore、book detail 對進度欄位的引用
- `test/features/reader`
- `docs/DATABASE.md`、`docs/reader_runtime.md`、`docs/reader_spec.md`

## 必做修補

即使退回，也要補以下東西：

1. 在舊版上建立「閱讀器行為凍結測試」。
2. 把 0.2.28 的 DB schemaVersion 保持向前，不允許降版。
3. 修復已知 scroll/slide restore 邊界問題。
4. 把 `ReadBookController` 中的 progress / restore / viewport command 抽出純邏輯測試。
5. 不再繼續把新功能塞回 controller。

## 退回步驟

1. 建立安全分支，例如 `reader-rollback-0.2.28`.
2. 從 `reader-0.2.28` 複製 reader 相關程式碼與 core schema 依賴。
3. 保留目前版本中與 reader 無關且已驗證的修復。
4. 跑 code generation。
5. 跑：

```bash
flutter analyze
flutter test test/features/reader
flutter test test/core test/features/book_detail test/features/bookshelf
```

6. 用舊資料庫、空資料庫、目前 dev 資料庫各測一次開書與進度恢復。

## 驗收條件

- 0.2.28 舊資料庫可直接打開。
- 書架、詳情頁、閱讀頁顯示同一個進度。
- scroll/slide 退出再進位置合理。
- app background 後進度不丟。
- source switch 後進度不歸零。

## 最終判斷

可以當短期 fallback，但不推薦採用。退回會把問題從「新版未收斂」變成「舊版難維護」。如果目標是把 reader 做好，應該只從 0.2.28 借行為與測試，不借整個主架構。


# 🎯 任務完成進度

## 核心邏輯與引擎層 (Core Engine & Logic)
- [x] **AnalyzeRule 對位**: 補全 `##` 正則切分、`{$...}` 模板替換、`@put` 變數儲存。
- [x] **正則分組支援**: 在 `makeUpRule` 中實作 `$1`, `$2` 等動態替換。
- [x] **大數據服務**: 整合 `RuleBigDataService` 並修復 `AnalyzeRuleBase` 讀取邏輯。
- [x] **系統維護**: 實作 `DefaultData._maintenance` 自動清理過期快取與搜尋歷史。
- [x] **JS 引擎 Mock**: 為測試環境提供 `key`, `page`, `result` 等變數 Mock，確保測試通過。

## 使用者介面層 (UI / Features)
- [x] **強健性解析**: 優化 `AppTheme` 與 `BookSource` 的 JSON 解析，防止類型不匹配導致崩潰。
- [x] **Lint 清理**:
  - 修復所有 `curly_braces_in_flow_control_structures`。
  - 修復所有 `use_build_context_synchronously` (透過 `context.mounted` 檢查)。
  - 修復所有 `dead_null_aware_expression` (包含 `sb.latestChapter` 等)。
  - 移除所有未使用的欄位與變數 (`_searchPage`, `length` 等)。
- [x] **對位 Android UI 邏輯**: 修正換源列表的排序與來源名稱顯示。

## 待辦事項 / 注意事項
- 目前僅剩 `Share` 類別的棄用建議 (info)，為維持編譯穩定暫不強制遷移至 `SharePlus` 實例。
- `QueryTTF` 仍為框架階段，未來需進一步實作 CMap 解析。

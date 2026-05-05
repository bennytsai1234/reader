# Reader x Legado 功能工作流程

## 目的

- 用於 `reader` 目前不存在的新行為，包含使用者明確要求的 Legado parity、相容性或遷移等價工作。
- 一般功能工作不要重新執行 Codebase Atlas；先用 [reader_legado_index.md](reader_legado_index.md) 定位，再使用模組文檔。
- 本 Atlas 已啟用 feature parity；功能流程可以把 `legado` 對應能力當作 parity source，但仍要先界定本次 feature boundary，不能把整個 `legado` 當成待辦清單。

## 工作流程

1. 保留使用者原始要求，並標記是否明確要求 Legado parity、相容性或遷移等價。
2. 打開 [reader_legado_index.md](reader_legado_index.md)，找出自然擁有新行為或狀態生命週期的主模組。
3. 閱讀主模組文檔與必要邊界模組文檔。
4. 若是 parity 工作，只查看模組文檔列出的 `legado` 對應區域，拆出需要對齊的使用者可見行為、資料契約、失敗處理與驗證點。
5. 定義功能邊界：包含行為、排除行為、介面、狀態、持久化、外部系統、使用者可見改變與非目標。
6. 若功能跨模組，依新行為或狀態生命週期選主模組；其他模組只保留明確介面責任。
7. 依主模組既有 pattern 實作，不直接移植 Android/Kotlin 架構。
8. 驗證新行為，包含必要的 parity 差異或相容性測試。
9. 若 ownership、API、資料流或模組邊界改變，更新受影響的 Atlas 文檔。
10. 依交付政策完成。

## 修改前／修改後閘門

當此工作流程被呼叫時，不要先改 code。先用 Atlas、程式碼檢查與必要的 `legado` 對應區域完成分析，並提供給使用者確認。

分析上半部可以包含工程細節，例如主模組、邊界模組、可能檔案、parity 差異、風險與檢查。最後部分必須只保留白話的修改前／修改後摘要：

- **修改前**：說明系統目前能做什麼、不能做什麼，或和要求的 parity 差在哪裡。
- **修改後**：說明這次功能會新增或改變什麼行為。

等待使用者明確確認後，才可以編輯檔案實作功能。

## 交付政策

提交並推送。完成驗證後建立聚焦 commit，確認目標 remote/branch 後推送；若 remote 或 branch 不清楚，推送前必須先詢問。

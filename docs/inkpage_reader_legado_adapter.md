# Inkpage Reader Codebase Atlas

這是本專案的 Codebase Atlas agent 入口。每次處理這個專案的工作都照以下步驟執行。

## 使用方式

1. 保留使用者原始請求。
1. 開啟 `inkpage_reader_legado_main_workflow.md` 並遵守它。
1. 在讀 atlas index 前，不要開始任何操作。
1. 使用者回報一律使用繁體中文與白話說明，不要向使用者暴露模組名、檔案路徑、函式名或程式碼片段。
1. 任何會改檔案的操作，都要先提供 Before / After 並等待使用者確認。
1. 完成時遵守交付方式：一般工作不自動 commit 或 push；只有使用者明確要求提交、推送，或正在走發布流程時才做。

## 不要做

- 不要在使用者沒有明確要求完整 rebuild 時重新執行 Codebase Atlas 初始化。
- 不要跳過 atlas index。
- 不要在使用者確認 Before / After 前改檔案。
- 不要把 Legado 額外功能當成本專案必須補齊的缺失。

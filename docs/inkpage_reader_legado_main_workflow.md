# Inkpage Reader x Legado Main Workflow

## 角色

這是本專案日常工作的唯一入口。使用者不需要知道 understand、change、validate workflow 的存在；agent 會依任務意圖自動路由，必要時組合多個 workflow。

## Workflow

1. 在任何其他操作前，先開啟 `docs/inkpage_reader_legado_index.md`，同時保留使用者原始請求與意圖。
1. 用一句白話確認這個專案是什麼：`這是 Flutter/Dart 小說閱讀器「墨頁」，參考 Legado 的小說閱讀相關概念，但以本專案現有功能為準。`
1. 依任務意圖路由：
   - 理解、說明、調查、可行性問題：使用 understand workflow。
   - 修改、bug fix、feature、optimization、refactor：使用 change workflow。
   - 驗證、review、安全檢查、重現、風險評估：使用 validate workflow。
   - 混合意圖：依 understand、validate、change 的順序組合。
1. 內部執行對應 workflow。
1. 用白話向使用者回報結果。
1. 任何需要改檔案的操作，都必須先提供 Before / After gate，並等待使用者明確確認。
1. 完成時遵守交付方式：一般工作不自動 commit 或 push；只有使用者明確要求提交、推送，或正在走發布流程時才做。

## 路由原則

- 意圖不清楚時，先做 understand，再判斷是否需要 validate 或 change。
- 絕不在沒有 Before / After 確認前改檔案。
- 組合 workflow 時，把前一階段結論傳給下一階段；除非下一階段需要尚未取得的資訊，否則不要重讀 index 或模組文件。
- 一般工作不要重新執行 Codebase Atlas；只有明確要求完整 rebuild、refresh、regenerate 或 rescan 時才可重建。

## 回報規則

- 使用者溝通使用繁體中文與白話說明。
- 使用者回報中不要暴露模組名、檔案路徑、函式名或程式碼片段；技術細節留在內部推理。
- Before / After 是唯一的人類確認介面。
- 參考 Legado 時，明確避免把 Legado 額外功能變成待辦或缺失。

## Before / After 格式

**Before**：用一到三句白話說明目前狀態，以及哪裡錯誤、不清楚、缺失或有風險。

**After**：用一到三句白話說明操作完成後會變成什麼狀態。

等待使用者明確確認後才執行。

## 連續工作模式

每次任務完成後，用白話詢問：

```text
還有其他需要處理的地方嗎？
```

如果使用者繼續提出新請求：

- 不要重讀 index。
- 直接延續路由判斷。
- 持續使用白話回報與 Before / After 機制。

只有使用者表示沒有其他事項時結束。

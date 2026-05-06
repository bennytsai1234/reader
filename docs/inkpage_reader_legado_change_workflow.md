# Inkpage Reader x Legado Change Workflow

## 角色

這是由 main workflow 內部路由的 agent workflow。使用者不需要知道這個 workflow 存在。

用於 bug fix、feature、optimization 與 refactor。

## 內部推理層

不要把這層輸出給使用者。

1. 保留使用者原始請求。
1. 接收任務與 main workflow 已讀過的 index 摘要。
1. 選擇最相關的模組文件與必要的邊界模組文件。
1. 內部分類任務：
   - Bug：目前行為錯誤或不穩。
   - Feature：要求新增行為。
   - Optimization：行為不變，改善品質或效能。
   - Refactor：預期行為不變，改變結構。
1. 內部校準範圍，讓 Before / After 準確：
   - 要改什麼。
   - 可能影響哪些下游。
   - 哪些邊界仍不確定。
   - 是否會碰到共享狀態、持久化、generated artifacts、測試或發布流程。
1. 只有需要時才讀程式碼、測試、文件、設定或 Legado 參考。
1. 如果參考 Legado，確認變更仍以本專案現有小說閱讀功能為準，不新增功能追齊。

## 對外回報層

1. 用下面的 Before / After 格式向使用者確認。
1. 等待使用者明確確認後，才修改任何檔案。
1. 實作變更。
1. 驗證受影響行為與邊界。
1. 完成時用一句白話說明已改變什麼；必要時補充未能執行的驗證。

## 回報規則

- 使用者溝通使用繁體中文與白話說明。
- 使用者回報中不要暴露模組名、檔案路徑、函式名或程式碼片段。
- Before / After 是唯一的人類確認介面。
- 技術細節留在內部推理。

## Before / After 格式

**Before**：用一到三句白話說明目前狀態，以及哪裡錯誤、缺失或有風險。

**After**：用一到三句白話說明修改完成後會變成什麼狀態。

等待使用者明確確認後，才執行任何改檔案操作。

## Atlas 更新條件

只有當變更真的改變模組邊界、所有權、外部 API 或已記錄的 repo 事實時，才更新受影響 atlas 文件。一般 bug fix 與小 feature 不需要更新 atlas。

## 交付方式

一般工作不自動 commit 或 push；只有使用者明確要求提交、推送，或正在走發布流程時才做。

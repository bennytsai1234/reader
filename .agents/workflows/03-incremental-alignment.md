---
description: "[3/4] 規格驅動移植實作：根據審計手冊的移植規格，精確還原 Android 邏輯至 iOS"
---

# 🔧 [3/4] 規格驅動移植工作流 (Spec-Driven Implementation) v2

本工作流是搬遷過程的「執行手臂」。它將 `/02-feature-parity` 產出的詳細審計手冊視為**藍圖**，進行精確的代碼移植。

---

## 🛠️ 強連動開發策略 (Referential strategy)

> [!IMPORTANT]
> **1. 規格優先 (Spec-First)**：實作前必須完整讀取 `FEATURE_AUDIT_v2.md` 中針對該資料夾的「移植規格說明」。禁止憑經驗猜測。
> **2. 原始碼三角形對位**：實作每段邏輯時，必須同時開啟：
>    - **地圖**：確認檔案職責位置。
>    - **Android 原始碼**：比對演算法細節與邊際處理（確保不漏掉任何一個 `if` 或 `try-catch`）。
>    - **iOS 目標檔案**：執行外科手術式植入。
> **3. 跨檔案協作 (Multi-file Orchestration)**：若規格要求分散實作（例如：一部分在 Provider，一部分在 Page），必須在同一個 Session 內完成。

---

## 執行步驟

### Step 1：藍圖讀取與定位
- 定位 `FEATURE_AUDIT_v2.md` 中的目標 GAP。
- 透過 `COMPREHENSIVE_FEATURE_MAPPING.md` 找到對應的 Android 參考路徑與 iOS 目標位置。

### Step 2：深度邏輯對標 (Deep Reference)
- **讀取 Android 原文**：不只是看 Method 名稱，要讀取內部的邏輯分支。
- **評估 Flutter 配適**：若 Android 使用了原生廣播 (Broadcast) 或 Service，對應至 Flutter 的 `MethodChannel` 或 `Stream` 方案。

### Step 3：外科手術式開發 (Surgical Patching)
- **優先採用 `replace`**：避免破壞現有的 UI 佈局或 Provider 狀態。
- **嵌入溯源註解**：在關鍵代碼旁加上 `// AI_PORT: GAP-XX derived from [AndroidFile.kt]`，方便日後維護。

### Step 4：實作後同步 (Sync Back)
- 修復完成後，回頭修改 `FEATURE_AUDIT_v2.md`：
  - 將對應的 `[ ]` 變更為 `[x]`。
  - 在「診斷詳情」旁加上 `✅ Done in [commit_hash/date]`。

---

## 🏗️ 代碼品質鐵律 (Implementation Mandate)
- **零 Placeholder**：產出的代碼必須能直接跑，不准留下 `// Todo: implement the rest`。
- **一致性校核**：修改後必須確認檔案依然符合 Dart 語法規範與專案風格。

---

## Git 備份
`git add . ; git commit -m "feat: spec-driven porting for [GAP-ID] ([目標邏輯])"`

---

## 下一步
→ 執行 **`/04-debug`** 進入分析與修復迴圈。

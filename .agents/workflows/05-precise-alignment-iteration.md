---
description: "[5/5] 精準對位迭代工作流：針對 Android 邏輯進行深度復刻與 Flutter 精準實作"
---

# 🎯 [5/5] 精準對位迭代工作流 (Precise Alignment) v1

本工作流專注於將 Android (Legado) 的核心功能「精確且穩定」地移植到 iOS (Flutter) 專案。不追求開發速度，但求邏輯對位、語法零警告與功能完善。
Legado 原始碼研讀 -> iOS 現狀分析 -> Flutter 實作 -> UI串接 -> 文檔更新
---

## 🔄 核心循環 (The Alignment Cycle)

### 1. 模組定位 (Gap Identification)
- 參考 `ios\ARCHITECTURE_REPORT.md`我們行動之前，一定要參考地圖來快速地找到對應的資料夾。

### 2. Android 原始碼審計 (Android Source Audit)
- 讀取關鍵檔案一次讀取一個。
- 總結核心職責。

### 3. Flutter 對位實作 (Flutter Implementation)
- 先列出資料夾下被拆分成多少個檔案，一次讀取所有的檔案，再到對應的檔案之中進行實作或修復。

### 4. 靜態分析與深度除錯 (Static Analysis & Hardening)
- 執行 `flutter analyze ios`。
- 必須修正所有問題，包含 `info` 級別的警告。
- 重複執行分析直到輸出為 `No issues found!`。

### 5. 備份 (Atomic Backup)
- 每完成一個功能點並通過分析後，立即提交 Git。
- 在每一個資料夾完成之後，參考 `ios\ARCHITECTURE_REPORT.md`然後再ios\finish.md寫入對應的資料夾，然後表示已完成
- `git add . ; git commit -m "feat: implement [模組] ([路徑]) and UI integration"`

---

## 🛠️ 常用指令
- **掃描 Android**: `Get-ChildItem -Path "legado\app\src\main\java\io\legado\app\ui\..." -Recurse`
- **驗證代碼**: `flutter analyze ios`
- **編譯測試**: `flutter build apk --debug` (用於 Android 邏輯驗證)

## 🏁 完成判定
- ✅ 功能邏輯與 Android 版對等。
- ✅ `flutter analyze` 無任何警告或錯誤。
---
description: "[4/4] 除錯與品質迴圈：自動掃描問題並循環修復直到歸零"
---

# 🐛 [4/4] 品質防禦與除錯迴圈 (Debug Loop) v1

本工作流結合了靜態分析與自動化修復循環，確保代碼在遷移過程中的品質。

---

## 🔁 迴圈機制 (Quality Loop)

> [!TIP]
> **自動演進**：本工作流預設執行修復循環。
> 1. **分析 (Analyze)**：執行 `flutter analyze` 獲取當前所有 Error/Warning。
> 2. **修復 (Fix)**：針對清單中的問題，結合根因分析與 Android 邏輯進行修復。
> 3. **驗證 (Verify)**：再次運行分析，若問題仍存在且未達最大輪次（預設 5 輪），則自動進入下一輪修復。

---

## 執行步驟

### Step 1：執行分析 (Baseline)
- 執行 `flutter analyze`。
- 若輸出結果為 "No issues found!" → 成功結束工作流。
- 若有問題，提取檔案路徑、行號與錯誤描述。

### Step 2：根因分析 (RCA)
- **錯誤定位**：讀取發生錯誤的 Dart 程式碼。
- **對照參考**：
  - 開啟 `COMPREHENSIVE_FEATURE_MAPPING.md` 找到對應的 Android 檔案。
  - 讀取 Android 原始碼，確認型別定義或邏輯意圖。
- **判定型別**：是語法錯誤、型別不匹配（Type Mismatch）、空值風險（Null Safety）還是邏輯誤解？

### Step 3：實作修復
- **優先使用 `replace`** 進行精確修正。
- 修正後，檢查相關聯的 Provider 或 Model 是否也需要相應調整。

### Step 4：循環判定 (Loop Condition)
- **宣告輪次**：目前為第 [i/5] 輪。
- **再次執行 Step 1**：
  - 如果 Error 數量減少且仍有剩餘 → 自動開始下一輪修復。
  - 如果出現新 Error → 優先解決新問題。
  - 如果 5 輪後仍未歸零 → 停止循環，並向使用者報告剩餘難點。

### Step 5：更新報告與 Git 備份
- 若 Bug 修復涉及原本的 Logic Gap，同步更新 `FEATURE_AUDIT_v2.md`。
- `git add . ; git commit -m "fix: resolve static analysis issues (cumulative loop fix)"`

---

## 完成判定
- ✅ `flutter analyze` 輸出為 0 issues 或已達到最大修復能力。
- ✅ 無損壞現有的業務逻辑。

---
description: "[1/4] 遞迴式結構映射：按資料夾逐層掃描，確保 Android 檔案 100% 對位或標記缺失"
---

# 📐 [1/4] 遞迴結構映射工作流 (Recursive Mapping) v6

本工作流採用「資料夾遞迴」模式，確保 Android 端（app & modules）的**每一個檔案**都能在 iOS 端找到對位，或被明確標記為缺失。

---

## 🌳 遞迴掃描策略 (Traversal Strategy)

> [!IMPORTANT]
> **1. 資料夾為核心**：一次僅處理一個資料夾。必須列出該資料夾下**所有**原始碼檔案。
> **2. 深度優先 (DFS)**：先處理子資料夾（Sub-folders），確認子層級清空後，再回退到父資料夾（Parent-folder）。
> **3. 100% 覆蓋率**：Android 檔案如果不對位 iOS，必須標記為 `❌ Missing/Missing Logic`，不得直接忽略。

---

## 執行步驟

### Step 1：選取掃描起點 (Entry Point)
- 從 `legado/app/` 或 `legado/modules/` 的最底層子資料夾開始。
- AI 會記錄當前掃描進度，確保不重覆。

### Step 2：執行「資料夾審核」 (Folder Audit)
1. **清點**：列出當前 Android 資料夾路徑下的所有 `.kt`, `.java` 檔案。
2. **對標**：
   - 搜尋 iOS `lib/` 中職責相同的 Dart 檔案。
   - **狀態判定**：
     - `✅ Matched`：找到邏輯對位。
     - `❌ Missing`：iOS 尚無此功能實作。
     - `⚠️ Partial`：功能散落在多個檔案或部分實作。

### Step 3：追加至地圖報告
- 使用 `replace` 工具將結果追加至 `COMPREHENSIVE_FEATURE_MAPPING.md`。
- **必須保留資料夾層級結構**，方便閱讀。

#### 地圖呈現格式
```markdown
## 📂 資料夾路徑：[Android Folder Path]

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `XyzActivity.kt` | 介面邏輯 | `xyz_page.dart` | ✅ Matched |
| `AbcHelper.kt` | 輔助工具 | - | ❌ Missing |
```

### Step 4：遞迴演進 (Recursive Step)
- 當前子資料夾完成後，移動至同層級的下一個子資料夾。
- 同層級全部完成後，向上移動至父資料夾執行 Step 2。

---

## Git 備份
`git add COMPREHENSIVE_FEATURE_MAPPING.md ; git commit -m "docs: recursive map update for [路徑]"`

---

## 完成判定
- ✅ **COMPREHENSIVE_FEATURE_MAPPING.md** 完整呈現了指定路徑下的所有檔案對位。
- ✅ 所有 Android 檔案均有 `✅` 或 `❌` 狀態，無遺漏。

---
description: "[2/4] 資料夾對位審計：針對地圖中的清單展開深度邏輯比對，產出移植規格"
---

# 🔍 [2/4] 資料夾對位審計工作流 (Folder-to-Folder Audit) v2

本工作流緊接在 `/01-structure-mapping` 之後。既然地圖已經清點了資料夾內的所有檔案，本工作流負責進行**原始碼級別的語義比對**。

---

## 🎯 審計策略 (Audit Strategy)

> [!IMPORTANT]
> **1. 以資料夾為邊界**：一次只審計一個在地圖中已完成清點的資料夾。
> **2. 雙重路徑分析**：
>    - **針對 `✅ Matched`**：比對 Method 簽名、核心演算法步驟、與 Android 的完成度差異。
>    - **針對 `❌ Missing`**：讀取 Android 源碼，產出其在 iOS 端應有的「移植規格說明」（該寫在哪、需要哪些依賴）。
> **3. 拒絕遺漏**：該資料夾下地圖列出的所有檔案，都必須在審計報告中有個案分析。

---

## 執行步驟

### Step 1：同步範圍 (Sync Scope)
- 讀取 `COMPREHENSIVE_FEATURE_MAPPING.md` 的最新章節。
- 確定本次審計的 Android 資料夾路徑。

### Step 2：深度對比 (Deep Dive)
- **對於每個 Android 檔案**：
  1. **讀取邏輯**：打開 Android 源碼，提取關鍵業務 Method (例如：`loadData`, `parseRules`)。
  2. **尋找 iOS 證據**：
     - 若為 `✅`：打開對應 Dart 檔案，比對邏輯對稱性。
     - 若為 `❌`：分析其職責，判斷在 Flutter 中應該實作在 Provider、Service 還是 UI 層。
  3. **判定缺口**：找出「雖然有檔案但漏掉的邊際處理」或「完全沒做的功能點」。

### Step 3：產出審計日誌 (Append only)
- 準備一段 Markdown 日誌，包含檔案級別的詳細診斷。
- **針對 `❌ Missing` 檔案的特殊處理**：產出一個「待實作清單 (Backlog)」。

#### 審計日誌格式
```markdown
<!-- AUDIT_FOLDER: [路徑] -->
## 🔍 審計報告：[Android Folder Path]

### 📄 檔案對比清單
| 檔案名稱 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `XyzActivity.kt` | ✅ Matched | iOS 版漏掉了 `onLongClick` 的處理，標註為 `Logic Gap`。 |
| `AbcHelper.kt` | ❌ Missing | **移植規格**：需在 `ios/util/` 新建對位類別，依賴於 `crypto` 庫。 |

### 🛠️ 待辦缺口 (Todo Gaps)
- [ ] GAP-[ID1]: 實作 Xyz 的長按選單。
- [ ] GAP-[ID2]: 移植 AbcHelper 邏輯。
<!-- AUDIT_FOLDER_END -->
```

### Step 4：追加至 FEATURE_AUDIT_v2.md
- 使用 `replace` 工具將上述日誌附加至 `FEATURE_AUDIT_v2.md` 的 EOF。

---

## Git 備份
`git add FEATURE_AUDIT_v2.md ; git commit -m "audit: detailed findings for [資料夾路徑]"`

---

## 下一步
→ 執行 **`/03-incremental-alignment`** 按照上述生成的「待辦缺口」進行實作。

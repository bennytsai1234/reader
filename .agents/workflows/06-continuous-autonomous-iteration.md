---
description: "[6/5] 全自動持續迭代工作流：跨模組的自主循環開發模式"
---

# 🚀 [6/5] 全自動持續迭代工作流 (Continuous Autonomous Iteration) v1

本工作流旨在透過「自主決策」與「精準對位」的結合，實現跨功能模組的無縫連續開發。適用於專案進入中後期，需要大規模補齊長尾功能缺口的情境。

---

## 🌀 持續迭代循環 (The Autonomous Loop)

### 1. 隊列排序 (Queueing)
- 自動掃描 `COMPREHENSIVE_FEATURE_MAPPING.md` 或 `FEATURE_AUDIT_v2.md`。
- 根據「交互頻率」與「邏輯依賴」自動決定下一個迭代目標。

### 2. 深度復刻 (Deep Cloning)
- **環境探索**: 主動深入 Android 端的 `help/config`、`service` 與 `ui` 目錄。
- **職責提取**: 不僅複製 UI，更要提取其背後的實體欄位、持久化鍵名（PreferKey）與非同步事件。

### 3. 增量實現 (Incremental Build)
- 遵循「基礎設施先行」原則：先擴展 Provider/Dao，再實作 Page/Widget。
- 確保新功能與現有模組（如：設定、閱讀器、書源管理）緊密聯動。

### 4. 品質守門 (Quality Guard)
- **強制分析**: 每一輪迭代後必須執行 `flutter analyze ios`。
- **零警告標準**: 任何 `info` 或 `warning` 必須在進入下一個模組前修正。
- **原子提交**: 確保 Git 歷史清晰，一模組一提交。

### 5. 自動切換 (Auto-Switch)
- 在完成「分析」與「提交」後，不等待使用者指令，主動提議或直接啟動下一個邏輯關聯模組的迭代。

---

## 🚦 穩定性保障
- **DEBUG 週期**: 每 5-10 輪小迭代後，執行一次全局 `/04-debug` 工作流。
- **編譯驗證**: 定期構建 `flutter build apk --debug` 確保所有平臺插件與代碼結構無損。

---

## 🏁 完成判定
- ✅ 完成所有標記為 `❌ Missing` 的核心模組。
- ✅ 專案進入「功能完善期」，開始轉向視覺美化與效能優化。

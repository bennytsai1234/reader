---
name: inkpage-reader
description: 使用 Inkpage Reader Codebase Atlas main workflow；canonical workflow 是 ../../../docs/inkpage_reader_legado_main_workflow.md。
---

# Inkpage Reader

這是薄型 Codebase Atlas 入口。Canonical workflow 是 `../../../docs/inkpage_reader_legado_main_workflow.md`。

## Workflow

1. 保留使用者目前的請求。
1. 開啟 `../../../docs/inkpage_reader_legado_main_workflow.md`，並以它作為唯一 workflow 來源。
1. 在檢查程式碼前，先從 atlas index 開始。
1. 使用繁體中文與白話做使用者溝通。
1. 如果 canonical workflow 要求 Before / After gate，先分析並等待使用者明確確認，才能改檔案。
1. 依照記錄的交付方式完成：一般工作不自動 commit 或 push；只有使用者明確要求，或任務是發布流程時才做。

## 不要做

- 不要在這裡複製或取代 canonical workflow 規則。
- 除非使用者明確要求完整 rebuild、refresh、regenerate 或 rescan，不要重新執行 Codebase Atlas。
- 不要把 Legado 的額外功能當成 Inkpage Reader 缺少的功能。

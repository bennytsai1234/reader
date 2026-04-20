# 墨頁 Inkpage 文檔索引

更新日期：2026-04-20

這份索引假設舊文檔全部失效，重新以目前 `reader` 程式碼與手動對照 `legado` 的結果為準。

## 先讀什麼

1. [../README.md](../README.md)  
   專案定位、目前支援範圍、建置與測試入口。
2. [architecture.md](architecture.md)  
   `reader` 目前真正的模組切法、責任邊界，以及和 `legado` 的大方向差異。
3. [reader_architecture_current.md](reader_architecture_current.md)  
   閱讀器 runtime 的現況，重點是 `ReadBookController`、chapter runtime、scroll/slide delegate。
4. [DATABASE.md](DATABASE.md)  
   Drift schema、DAO、migration，還有目前和 `legado` 資料層的差異。
5. [roadmap.md](roadmap.md)  
   依照現有程式碼與測試狀態整理出的優先級，不沿用舊里程碑敘事。
6. [next_stage_handoff.md](next_stage_handoff.md)  
   如果今天要接手這個 repo，應該先做什麼、先不要做什麼。
7. [source_audit_backlog.md](source_audit_backlog.md)  
   已改寫為 `reader` 與 `legado` 的手動對照紀錄，不再是舊的 source batch audit 日誌。
8. [slide-chapter-preload-plan.md](slide-chapter-preload-plan.md)  
   閱讀器平移翻頁預載機制的現況說明。

## 每份文檔回答什麼

| 文件 | 回答 |
| --- | --- |
| `README.md`（根目錄） | 這個專案現在是什麼，不是什麼，怎麼跑 |
| `architecture.md` | 現在的模組真源在哪，和 `legado` 的邊界差在哪 |
| `reader_architecture_current.md` | 閱讀器主控、runtime cache、restore、TTS、view delegate 如何接起來 |
| `DATABASE.md` | 目前有哪些表、DAO、真源欄位，哪些設計還是過渡態 |
| `roadmap.md` | 目前最值得修的基礎能力缺口是什麼 |
| `next_stage_handoff.md` | 接手順序、驗證方式、已知風險 |
| `source_audit_backlog.md` | `reader` 對 `legado` 的功能與架構差異，哪些已對齊、哪些刻意不做、哪些尚未收尾 |
| `slide-chapter-preload-plan.md` | slide 模式章節預載目前怎麼工作，還有哪些限制 |

## 維護規則

- 只寫能由目前程式碼或測試直接驗證的事。
- 文件與程式衝突時，以程式為準，先改文件。
- 不再沿用「已完成 / 未完成」的舊口號，如果程式碼不支持，就直接寫不支持。
- `legado` 只作為對照與 compatibility spec，不再當成需要逐頁複製的產品清單。
- 專項文檔可以保留，但必須說清楚它是現況、歷史記錄，還是局部設計稿。

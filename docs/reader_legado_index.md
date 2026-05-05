# Reader x Legado 模組索引

## 目的與使用方式

- 這份索引用來在修改程式碼前快速定位 `reader` 的主要模組；細節請進入各模組文檔。
- Codebase Atlas 通常只在專案環境準備好後初始化一次；後續介紹、bug、功能、優化、調查、重構或驗證工作，應先使用本索引與對應工作流程文檔，不要重新執行 Codebase Atlas。
- 只有使用者明確要求 rebuild、refresh、regenerate 或 rescan 時，才重新執行 Codebase Atlas；這代表要重新掃描完整 codebase，並依目前程式碼 reality 重建索引與模組文檔。
- 輸出語言：Traditional Chinese。
- Atlas 模式：reference-assisted，目標專案是 `reader`，參考專案是 `legado`。
- Feature parity：enabled。未來功能工作可以把 `legado` 對應能力當作相容或對齊來源，但仍要先界定本次使用者要求、主模組與非目標；不要一次性搬入所有參考功能。
- 後續工作流交付政策：提交並推送。完成驗證後建立聚焦 commit，確認目標 remote/branch 後推送；若 remote 或 branch 不清楚，推送前必須先詢問。
- `legado` 是參考資料，用來借鏡責任邊界、流程順序、失敗處理、穩定化策略與明確要求的 parity 行為。目標專案仍以 `reader` 的 Flutter/Dart 架構、資料模型、測試與使用者範圍為準。

## 工作流程入口

已產生薄型 Codex skills；它們只會導向 canonical `docs/` 工作流程，不能取代本索引或複製完整規則。

- `.agents/skills/reader-legado-introduction/SKILL.md`
- `.agents/skills/reader-legado-bug/SKILL.md`
- `.agents/skills/reader-legado-feature/SKILL.md`
- `.agents/skills/reader-legado-optimization/SKILL.md`
- `.agents/skills/reader-legado-investigation/SKILL.md`
- `.agents/skills/reader-legado-refactor/SKILL.md`
- `.agents/skills/reader-legado-validation/SKILL.md`

## 工作流程文檔

- [介紹工作流程](reader_legado_introduction_workflow.md)
- [Bug 工作流程](reader_legado_bug_workflow.md)
- [功能工作流程](reader_legado_feature_workflow.md)
- [優化工作流程](reader_legado_optimization_workflow.md)
- [調查工作流程](reader_legado_investigation_workflow.md)
- [重構工作流程](reader_legado_refactor_workflow.md)
- [驗證工作流程](reader_legado_validation_workflow.md)

## 模組列表

- [App Shell](reader_legado/app_shell.md)
- [Bookshelf](reader_legado/bookshelf.md)
- [Discovery And Search](reader_legado/discovery_and_search.md)
- [Book Detail](reader_legado/book_detail.md)
- [Reader Runtime](reader_legado/reader_runtime.md)
- [Source Manager And Browser](reader_legado/source_manager_and_browser.md)
- [Rules And Local Books](reader_legado/rules_and_local_books.md)
- [Settings And Cache](reader_legado/settings_and_cache.md)
- [Integration And Diagnostics](reader_legado/integration_and_diagnostics.md)

## 模組摘要

### App Shell

啟動、DI、全域 Provider、主導航、主題與啟動錯誤恢復都從這裡開始。若症狀發生在進入功能頁前、全域狀態沒有生效、後台工作初始化失敗，先從這個模組查。

### Bookshelf

書架列表、排序、批次操作、本地書匯入、書籍更新檢查與批次下載排程入口都在這裡。若問題從書架觸發，或書架資料與閱讀進度、詳情頁不同步，先從這個模組查。

### Discovery And Search

探索入口、探索結果、跨書源搜尋、搜尋歷史與搜尋結果篩選都在這裡。若問題是來源結果不出現、搜尋排序錯、結果進入詳情前就不一致，先從這個模組查。

### Book Detail

書籍詳情、目錄、加入書架、換源、換封面、單本快取與下載入口都在這裡。若資料進入詳情後才錯，或換源後污染進度、封面、章節，先從這個模組查。

### Reader Runtime

`reader_v2` 的閱讀主線，包含內容載入、排版、渲染、scroll/slide viewport、閱讀進度、TTS、自動翻頁、書籤與閱讀器內設定。若問題發生在閱讀畫面、翻頁、章節切換或進度保存，先從這個模組查。

### Source Manager And Browser

書源匯入、清單、排序、分組、編輯、除錯、批次校驗、WebView 登入、驗證碼與 Cookie 回寫都在這裡。若來源健康度、規則編輯、登入驗證或書源校驗牽涉到搜尋/閱讀，先從這個模組查。

### Rules And Local Books

書源規則解析引擎、JavaScript 擴充、CSS/JSONPath/XPath/regex parser、替換規則，以及 TXT/EPUB/UMD 本地書解析都在這裡。若文字內容本身錯、規則解析不相容、本地書匯入或章節內容讀取有問題，先從這個模組查。

### Settings And Cache

偏好設定、TTS 設定、閱讀顯示設定、下載任務、章節內容儲存、備份與還原在這裡。若設定不生效、離線內容或下載狀態不一致、備份還原失敗，先從這個模組查。

### Integration And Diagnostics

Deep link、分享匯入、本地檔案關聯、關於頁、crash log 與 app log 在這裡。若問題來自 app 外部入口、匯入對話、錯誤資訊不足或診斷頁，先從這個模組查。

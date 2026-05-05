# Reader x Legado Atlas Index

## Purpose And Usage

- Use this index to locate the relevant `reader` module before inspecting code.
- Keep this document high level; put implementation routing details in the module documents.
- Codebase Atlas is normally run once to initialize or deliberately rebuild this map.
- For later understanding, change, or validation work, use the workflow docs listed below instead of running Codebase Atlas again.
- Run Codebase Atlas again only for an explicit rebuild, refresh, regenerate, or rescan. That means scanning the full codebase again and rebuilding this index from current repository reality.
- This repository asks project-rule discussion to use Traditional Chinese, so generated atlas content is written in Traditional Chinese.

## Decisions

- Atlas mode: reference-assisted.
- Target project: `reader`, the Flutter/Dart app `inkpage_reader`.
- Reference project: `legado`, the Android/Kotlin Legado implementation supplied as the reference repository.
- Workflow delivery policy: commit and push.
- Workflow entrypoints: canonical docs plus thin Codex skill adapters.
- Feature parity: disabled. Legado is guidance for boundaries, flow design, failure handling, diagnostics, testing patterns, and naming alignment; missing Legado features are not reader bugs or backlog items unless a later user request explicitly asks for parity, compatibility, migration equivalence, or reference-driven expansion.
- Reference boundary: target project reality wins. Build module ownership from `reader`; consult Legado only for the corresponding area named in each module doc.

## Workflow Entrypoints

Thin Codex skill adapters point back to the canonical workflow docs and do not replace them:

- `.agents/skills/reader-legado-understand/SKILL.md`
- `.agents/skills/reader-legado-change/SKILL.md`
- `.agents/skills/reader-legado-validate/SKILL.md`

## Workflow Docs

- Understand workflow: [reader_legado_understand_workflow.md](reader_legado_understand_workflow.md)
- Change workflow: [reader_legado_change_workflow.md](reader_legado_change_workflow.md)
- Validate workflow: [reader_legado_validate_workflow.md](reader_legado_validate_workflow.md)

## Module List

- [App Shell](reader_legado/app_shell.md)
- [Data Model And Persistence](reader_legado/data_model_and_persistence.md)
- [Bookshelf](reader_legado/bookshelf.md)
- [Discovery And Search](reader_legado/discovery_and_search.md)
- [Book Detail](reader_legado/book_detail.md)
- [Reader Runtime](reader_legado/reader_runtime.md)
- [Source Manager And Browser](reader_legado/source_manager_and_browser.md)
- [Rules And Local Books](reader_legado/rules_and_local_books.md)
- [Settings And Cache](reader_legado/settings_and_cache.md)
- [Integration And Diagnostics](reader_legado/integration_and_diagnostics.md)

## Module Summaries

### App Shell

啟動、DI、全域 Provider、主導航、主題、啟動錯誤恢復與後台初始化都從這裡開始。若症狀發生在進入功能頁前、全域狀態沒有生效、Workmanager 或驗證協調器初始化失敗，先從這個模組查。

### Data Model And Persistence

Drift schema、DAO、domain model、serialization、storage path 與資料契約在這裡。若工作牽涉 schema、generated `.g.dart`、模型欄位、備份相容、書源 JSON 相容或跨模組資料一致性，先從這個模組查。

### Bookshelf

書架列表、排序、批次操作、本地書匯入、書籍更新檢查與批次下載排程入口都在這裡。若問題從書架觸發，或書架資料與閱讀進度、詳情頁、下載任務不同步，先從這個模組查。

### Discovery And Search

探索入口、探索結果、跨書源搜尋、搜尋歷史、搜尋範圍與結果篩選都在這裡。若問題是來源結果不出現、搜尋排序錯、探索分頁 stale response、結果進入詳情前就不一致，先從這個模組查。

### Book Detail

書籍詳情、目錄、加入書架、換源、換封面、單本快取與下載入口都在這裡。若資料進入詳情後才錯，或換源後污染進度、封面、章節、正文快取，先從這個模組查。

### Reader Runtime

`reader_v2` 的閱讀主線，包含內容載入、排版、渲染、scroll/slide viewport、進度保存、TTS、自動翻頁、書籤與閱讀器內設定。若問題發生在閱讀畫面、翻頁、章節切換、定位恢復或朗讀跟隨，先從這個模組查。

### Source Manager And Browser

書源匯入、清單、排序、分組、編輯、除錯、批次校驗、WebView 登入、驗證碼與 Cookie 回寫都在這裡。若來源健康度、規則編輯、登入驗證或書源校驗牽涉到搜尋/閱讀，先從這個模組查。

### Rules And Local Books

書源規則解析引擎、JavaScript 擴充、CSS/JSONPath/XPath/regex parser、替換規則，以及 TXT/EPUB/UMD 本地書解析都在這裡。若文字內容本身錯、規則解析不相容、本地書匯入或章節內容讀取有問題，先從這個模組查。

### Settings And Cache

偏好設定、閱讀/TTS 設定、下載任務、章節內容儲存、備份與還原在這裡。若設定不生效、離線內容或下載狀態不一致、備份還原失敗，先從這個模組查。

### Integration And Diagnostics

Deep link、分享匯入、本地檔案關聯、關於頁、crash log、app log 與發布流程在這裡。若問題來自 app 外部入口、匯入對話、錯誤資訊不足、診斷頁或 release workflow，先從這個模組查。

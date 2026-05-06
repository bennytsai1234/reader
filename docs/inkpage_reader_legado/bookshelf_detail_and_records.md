# 書架、書籍詳情與紀錄

## 目前責任

- 管理使用者書架、排序、批次更新、匯入、本地或線上書籍的詳情、章節列表、封面、快取狀態、加入/移除書架、換源入口、書籤與閱讀紀錄。

## 範圍

- Bookshelf：`lib/features/bookshelf/`。
- Book detail：`lib/features/book_detail/`。
- Bookmark/read record：`lib/features/bookmark/`、`lib/features/read_record/`。
- Supporting services：`BookSourceService`、`BookCoverStorageService`、`BookshelfExchangeService`、`BookshelfStateTracker`。
- 測試：`test/features/bookshelf/`、`test/features/book_detail/`、`test/features/read_record/`。

## 依賴與影響

- 依賴 Book/Chapter/Bookmark/ReadRecord DAO、source rules、WebBook pipeline、local book service、download service 與 reader progress。
- 下游影響 Reader V2 開書、閱讀進度恢復、下載、封面顯示、換源與備份。
- 書籍詳情是搜尋/發現結果進入可閱讀書籍資料的主要轉換點。

## 關鍵流程

- 書架載入 `BookDao.getInBookshelf()` 並依使用者排序模式排列。
- 書籍詳情初始化時 upsert book、載入 source、抓詳情、載入章節，並更新封面與快取狀態。
- 加入書架會保存書籍與章節；移除書架會更新或刪除相關資料。
- 章節列表可搜尋、反轉、刷新；章節 tap 會進入 Reader V2。
- 書籤與閱讀紀錄各自透過 DAO/provider 顯示並導回閱讀位置。

## 常見修改起點

- 書架列表、排序、刷新：先看 `BookshelfProvider` 與 mixins。
- 書籍詳情載入、章節、封面、加入書架：先看 `BookDetailProvider`。
- 換源：先看 `features/book_detail/source/`。
- 書籤：先看 `BookmarkProvider` 與 Reader V2 bookmark controller 的互動。
- 閱讀紀錄：先看 `ReadRecordProvider` 與 reader progress 保存路線。

## 修改路線

- 改書籍生命週期時，同步 Book DAO、Chapter DAO、Reader V2 open target 與備份資料。
- 改章節列表時，確認線上章節、本地章節、下載章節與閱讀進度都仍用一致 index。
- 改封面時，同步 remote URL、local path、custom cover 與 cache cleanup。

## 已知風險

- `BookDetailProvider` 同時處理資料載入、狀態顯示、快取狀態與下載入口，改動容易跨界。
- 線上書籍與本地書籍共用 `Book`/`Chapter` 模型，但內容讀取路徑不同。
- 閱讀進度欄位同時包含 chapter index、char offset 與 visual offset，需和 Reader V2 保持一致。

## 參考備註

- Legado 對應區域是 `ui/book/info`、`ui/book/manage`、`ui/book/bookmark`、`ui/about/ReadRecordActivity.kt`。
- 本專案以小說書架與閱讀詳情為主，不需要補齊 Legado 的所有管理活動或 remote book 功能。

## 不要做

- 不要讓書籍詳情直接重寫 parser 或 network 規則。
- 不要把 reader progress 的格式私下改掉而不同步 Reader V2。
- 不要把本地書當成線上書源的一種來硬套 source health。

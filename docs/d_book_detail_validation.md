# D 系列書籍詳情功能驗證手冊

這份文件用來驗證「D 系列：書籍詳情」功能。當書籍詳情、目錄、換源、封面、匯出、單本快取、預下載、單本更新或書源調試出問題時，先照這份文件查，不需要從整個系統重新翻起。

## 適用範圍

- 書籍詳情頁：`lib/features/book_detail/book_detail_page.dart`
- 書籍詳情狀態：`lib/features/book_detail/book_detail_provider.dart`
- 詳情頁頭部：`lib/features/book_detail/widgets/book_info_header.dart`
- 目錄工具列：`lib/features/book_detail/widgets/book_info_toc_bar.dart`
- 換源彈窗：`lib/features/book_detail/widgets/change_source_sheet.dart`
- 換封面彈窗：`lib/features/book_detail/change_cover_sheet.dart`
- 匯出全書：`lib/core/services/export_book_service.dart`
- 封面資產：`lib/core/services/book_cover_storage_service.dart`
- 正文快取：`lib/features/reader/engine/reader_chapter_content_store.dart`
- 正文快取 DAO：`lib/core/database/dao/reader_chapter_content_dao.dart`
- 書籍 / 章節 / 書源 DAO：`lib/core/database/dao/book_dao.dart`、`lib/core/database/dao/chapter_dao.dart`、`lib/core/database/dao/book_source_dao.dart`
- 書源解析：`lib/core/services/book_source_service.dart`
- 背景下載：`lib/core/services/download_service.dart`
- 閱讀器入口：`lib/features/reader/reader_page.dart`
- 閱讀器開書目標：`lib/features/reader/runtime/models/reader_open_target.dart`
- 書源編輯與調試：`lib/features/source_manager/source_editor_page.dart`、`lib/features/source_manager/source_debug_page.dart`

## 快速驗證命令

```bash
flutter analyze
flutter test test/features/book_detail
```

與換源、匯出、預下載互動相關的補充驗證：

```bash
flutter test test/features/book_detail \
  test/features/reader/change_source_provider_test.dart \
  test/features/reader/change_source_item_test.dart
```

全專案驗證：

```bash
flutter test
```

## 功能表

| 編號 | 功能 | 現況 | 主要驗證點 |
| --- | --- | --- | --- |
| D1 | 書籍詳情 → 讀書 / 繼續閱讀 | 保留 | Header 主按鈕用 `ReaderOpenTarget.resume(book)` 開閱讀器 |
| D2 | 點章節 → 從指定章節打開閱讀器 | 保留 | 章節列表項用 `ReaderOpenTarget.chapterStart(index)` 開閱讀器 |
| D3 | 加入 / 移出書架 | 修復後保留 | 加入會保存章節 metadata；移出需確認，成功後提供撤銷 |
| D4 | 換源 | 修復後保留 | 搜尋候選、篩選來源、切換後保留進度與書架狀態 |
| D5 | 搜尋章節 / 章節排序 / 定位目前章節 | 修復後保留 | 搜尋、正倒序、定位目前閱讀章節與高亮目前章節 |
| D6 | 換封面 / 查看封面 | 保留 | 長按封面查看大圖；選網路封面、手動 URL 或本地圖片更新封面 |
| D7 | 匯出全書 | 修復後保留 | 空章節阻擋；缺章時可取消、先下載、只匯出快取或補抓後匯出 |
| D8 | 移除本書正文 | 修復後保留 | 需確認後刪除本書正文快取並刷新快取狀態 |
| D9 | 編輯書籍資訊 | 修復後保留 | 可編輯書名、作者、簡介、分類、封面、來源名稱、目錄 URL、自訂標籤 |
| D10 | 查看 / 調試目前書源 | 保留 | 點來源可看狀態，進書源詳情或以書名作 debug key 進調試頁 |
| D11 | 查看本書快取狀態 | 新增後保留 | 顯示已快取章節、總章節、正文大小、封面大小、最近快取時間 |
| D12 | 清除本書快取 | 新增後保留 | 可清正文、清封面、清全部，操作前需確認 |
| D13 | 預下載後續章節 | 新增後保留 | 從目前章節到結尾、後 10 章、後 50 章、全書、未下載、指定範圍 |
| D14 | 單本書更新檢查 | 新增後保留 | 手動重新抓詳情與目錄，回報新增章節數並保存 `lastCheckTime` |
| D15 | 顯示來源狀態 | 新增後保留 | Header 顯示來源健康狀態 chip；異常時顯示警示與換源入口 |
| D16 | 相同書籍候選列表 | 修復後保留 | 換源候選以同書名過濾，保留作者校驗、刷新與來源篩選 |
| D17 | 書籍操作撤銷 / 確認 | 新增後保留 | 移出書架有確認與撤銷；清正文/封面/全部快取需確認 |
| D18 | 搜尋結果進詳情 | 保留 | `SearchBook` 會轉為 `Book`，必要時先寫入本地資料庫 |
| D19 | 既有書籍資料復用 | 保留 | 若 DB 已有同 `bookUrl`，詳情頁使用既有書籍與書架狀態 |
| D20 | 線上詳情與目錄載入 | 保留 | 書源可閱讀時抓詳情與目錄；失敗時用既有資訊降級 |
| D21 | 本地書詳情行為 | 保留 | 本地書顯示來源狀態為「本地」，不允許背景預下載 |
| D22 | 來源異常恢復入口 | 新增後保留 | 書源停用、不可閱讀或目錄失敗時顯示原因與換源按鈕 |
| D23 | 章節 metadata 保存 | 保留 | 加入書架或預下載前保存章節資料，避免下載/閱讀找不到章節 |
| D24 | 封面本地資產保存 | 保留 | 顯示封面會嘗試保存 display cover；快取狀態可統計封面大小 |
| D25 | 快取狀態重新整理 | 新增後保留 | 詳情頁快取卡片與 dialog 都可手動刷新 |
| D26 | 換源失敗提示 | 新增後保留 | 換源失敗不關閉彈窗，顯示 snackbar 錯誤 |
| D27 | 換源後資料遷移 | 修復後保留 | 切換來源後保留閱讀進度、自訂封面、自訂簡介、自訂標籤與書架狀態 |
| D28 | 匯出缺失章節補抓 | 新增後保留 | 選「補抓並匯出」時用目前書源抓缺失正文並寫入快取 |
| D29 | 目錄目前章節高亮 | 新增後保留 | 目前閱讀章節有選中狀態、定位 icon 與「目前」標記 |
| D30 | 書架刷新事件 | 保留 | 加入、移出、換源、更新檢查會 fire `AppEventBus.upBookshelf` |
| D31 | 已移除：閱讀器來源 fallback sheet | 移除 | 未接線的 `ReaderSourceFallbackSheet` 已刪除，不列為 D 系列能力 |

## 驗證步驟

### D1-D2 讀書、繼續閱讀與指定章節開啟

入口鏈路：

```text
BookDetailPage
  -> BookInfoHeader 開始閱讀 / 繼續閱讀
  -> ReaderPage(book, openTarget: ReaderOpenTarget.resume(book))

BookDetailPage 章節列表
  -> ListTile.onTap
  -> ReaderPage(book, openTarget: ReaderOpenTarget.chapterStart(chapter.index))
```

手動驗證：

1. 從搜尋結果、發現列表或書架進入任一本書籍詳情。
2. 若 `book.chapterIndex == 0` 且 `book.charOffset == 0`，Header 主按鈕應顯示 `開始閱讀`。
3. 點 `開始閱讀`，預期進入閱讀器並從書籍目前進度開啟。
4. 在閱讀器翻到非第一章或非起始位置，返回詳情頁。
5. Header 主按鈕應顯示 `繼續閱讀`。
6. 點 `繼續閱讀`，預期用既有 `chapterIndex` / `charOffset` 恢復閱讀。
7. 回到詳情頁，在章節列表點任一章。
8. 預期閱讀器從該章開頭開啟。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| Header 閱讀按鈕 | `features/book_detail/widgets/book_info_header.dart` |
| 章節點擊 | `features/book_detail/book_detail_page.dart` / `SliverList` |
| 閱讀器入口 | `features/reader/reader_page.dart` |
| 開書目標 | `features/reader/runtime/models/reader_open_target.dart` |

常見故障定位：

- 按鈕文字不對：檢查 `book.chapterIndex`、`book.charOffset` 是否在閱讀器離開時寫回。
- 點章節仍從上次位置開啟：檢查章節列表是否使用 `ReaderOpenTarget.chapterStart()`。
- 詳情頁章節為空：看 D20 的詳情與目錄載入流程。

### D3 / D17 加入、移出書架與撤銷

入口鏈路：

```text
BookInfoHeader 放入書架 / 移出書架
AppBar library icon
  -> _handleBookshelfToggle()
  -> BookDetailProvider.setInBookshelf(value)
  -> BookDao.upsert(book)
  -> ReaderChapterContentStore.saveChapterMetadata()
  -> AppEventBus.upBookshelf
```

手動驗證：

1. 從搜尋結果進入一本未加入書架的書。
2. 點 Header `放入書架` 或 AppBar 加入書架 icon。
3. 預期顯示 `已加入書架`，返回書架可看到該書。
4. 回詳情頁，點 `移出書架`。
5. 預期先出現確認 dialog，取消時不應移出。
6. 再次移出並確認，預期顯示 `已移出書架` snackbar。
7. 點 snackbar `撤銷`，預期書籍回到書架。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| UI 入口與確認 | `features/book_detail/book_detail_page.dart` / `_handleBookshelfToggle()` |
| 狀態切換 | `features/book_detail/book_detail_provider.dart` / `setInBookshelf()` |
| 章節 metadata | `features/book_detail/book_detail_provider.dart` / `_saveChapterMetadataIfPossible()` |
| 書架刷新事件 | `core/engine/app_event_bus.dart` |

常見故障定位：

- 加入後書架不刷新：檢查 `AppEventBus.upBookshelf` 是否 fire，書架頁是否有監聽。
- 加入失敗後 UI 仍顯示已加入：檢查 `setInBookshelf()` catch 是否回復 previous 狀態。
- 撤銷無效：檢查 snackbar action 是否呼叫 `setInBookshelf(true)`。

### D4 / D16 / D26 / D27 換源與候選列表

入口鏈路：

```text
BookDetailPage 換源
  -> ChangeSourceSheet
  -> ChangeSourceProvider(book)
  -> ChangeSourceFilterBar
  -> ChangeSourceItem.onTap
  -> BookDetailProvider.changeSource(searchBook)
  -> Book.migrateTo()
  -> ChapterDao.deleteByBook() / insertChapters()
  -> BookDao.upsert(book)
```

手動驗證：

1. 準備一本可被多個書源搜尋到的線上書。
2. 進入書籍詳情，點 Header `換源` 或來源異常提示中的 `換源`。
3. 預期底部彈窗顯示相同書名候選列表。
4. 使用搜尋/篩選欄縮小來源範圍。
5. 切換 `校驗作者`，確認候選結果會重搜或重新過濾。
6. 點目前來源，預期不可切換。
7. 點其他來源，成功時應顯示成功 snackbar 並關閉彈窗。
8. 換源後預期書名、作者、章節列表更新，但閱讀進度、是否在書架、自訂封面、自訂簡介、自訂標籤保留。
9. 用失效書源或模擬解析錯誤換源，預期顯示錯誤 snackbar，彈窗不關閉。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 換源彈窗 | `features/book_detail/widgets/change_source_sheet.dart` |
| 換源搜尋 | `features/reader/source/change_source_provider.dart` |
| 候選項目 | `features/reader/widgets/change_source_item.dart` |
| 篩選 UI | `features/reader/widgets/change_source_filter_bar.dart` |
| 詳情換源 | `features/book_detail/book_detail_provider.dart` / `changeSource()` |
| 資料遷移 | `core/models/book.dart` / `migrateTo()` |

常見故障定位：

- 候選列表為空：先確認其他書源可搜尋，並檢查目前只顯示同書名候選。
- 換源後章節還是舊來源：檢查 `ChapterDao.deleteByBook()` 和 `insertChapters()` 是否成功。
- 換源後進度丟失：檢查 `Book.migrateTo()` 是否保留 `chapterIndex`、`charOffset`、`readerAnchorJson`。
- 錯誤時彈窗直接關閉：檢查 `ChangeSourceSheet` 是否只在 `outcome.success` 時 `Navigator.pop()`。

### D5 / D29 搜尋目錄、排序與定位目前章節

入口鏈路：

```text
BookInfoTocBar
  -> 搜尋 icon -> _showSearchTocDialog() -> BookDetailProvider.setSearchQuery()
  -> 定位 icon -> _locateCurrentChapter() -> resetTocViewForCurrentChapter()
  -> 排序 icon -> BookDetailProvider.toggleSort()
```

手動驗證：

1. 進入有多章的書籍詳情。
2. 點目錄搜尋 icon，輸入章節標題關鍵字。
3. 預期標題變成 `搜尋結果 (N/M 章)`，列表只顯示命中章節。
4. 點排序 icon，預期目錄正序 / 倒序切換，icon 與 tooltip 更新。
5. 閱讀器先讀到中間章節，再回詳情頁。
6. 點定位 icon，預期清空搜尋、恢復正序，列表滾到目前章節附近。
7. 目前閱讀章節應有選中狀態、定位 icon 與 `目前` 標記。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 目錄工具列 | `features/book_detail/widgets/book_info_toc_bar.dart` |
| 搜尋目錄 | `features/book_detail/book_detail_provider.dart` / `setSearchQuery()` |
| 排序 | `features/book_detail/book_detail_provider.dart` / `toggleSort()` |
| 定位目前章節 | `features/book_detail/book_detail_page.dart` / `_locateCurrentChapter()` |
| 目前章節索引 | `features/book_detail/book_detail_provider.dart` / `displayIndexForChapter()` |

常見故障定位：

- 搜尋後定位失敗：定位前應呼叫 `resetTocViewForCurrentChapter()` 清搜尋並恢復正序。
- 目前章節沒有高亮：檢查 list item 是否用 `chapter.index == currentBook.chapterIndex`。
- 滾動位置不準：目前用固定 item 高度估算，若章節 item 高度改動需同步 `_locateCurrentChapter()` offset。

### D6 / D24 換封面、查看封面與封面快取

入口鏈路：

```text
BookInfoHeader 封面長按
  -> _showPhotoView()

BookDetailPage menu 換封面
  -> ChangeCoverSheet
  -> ChangeCoverProvider.init(bookName, author)
  -> BookDetailProvider.updateCover(url)
  -> BookCoverStorageService.ensureDisplayCoverStored()
```

手動驗證：

1. 進入有封面的書籍詳情。
2. 長按封面，預期打開黑底大圖查看頁。
3. AppBar 選單點 `換封面`。
4. 選擇搜尋到的封面、手動輸入 URL，或從相簿選圖片。
5. 預期詳情頁封面更新。
6. 重新進入詳情頁，預期自訂封面仍保留。
7. 查看本書快取，預期封面大小可能增加。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 封面顯示 | `core/widgets/book_cover_widget.dart` |
| 查看大圖 | `features/book_detail/book_detail_page.dart` / `_showPhotoView()` |
| 換封面彈窗 | `features/book_detail/change_cover_sheet.dart` |
| 更新封面 | `features/book_detail/book_detail_provider.dart` / `updateCover()` |
| 封面資產 | `core/services/book_cover_storage_service.dart` |

常見故障定位：

- 本地圖片看不到：檢查 URL 是否為 `file://` 或 `local://`，以及檔案是否仍存在。
- 換封面後又變回原封面：檢查 `customCoverUrl` / `customCoverLocalPath` 是否被後續詳情刷新覆蓋。
- 封面快取大小不變：檢查 `ensureDisplayCoverStored()` 是否成功寫入 book asset dir。

### D7 / D28 匯出全書與缺失章節處理

入口鏈路：

```text
BookDetailPage menu 匯出全書
  -> _handleExport()
  -> refreshCacheStatus()
  -> ExportBookService.exportToTxt(book, fetchMissingRemote: ...)
  -> ReaderChapterContentDao.getEntry()
  -> LocalBookService.getContent() 或 BookSourceService.getContent()
  -> SharePlus.share()
```

手動驗證：

1. 進入有章節的書籍詳情，點 `匯出全書`。
2. 若章節數為 0，預期提示 `沒有可匯出的章節`。
3. 對本地書匯出，預期可從本地內容讀取正文並分享 TXT。
4. 對線上書但正文快取完整，預期直接建立匯出檔。
5. 對線上書且正文快取不完整，預期出現 `匯出可能不完整` dialog。
6. 選 `取消`，預期不匯出。
7. 選 `先下載缺失章節`，預期加入背景下載佇列，不立即匯出。
8. 選 `只匯出已快取`，預期只把已有正文寫進 TXT。
9. 選 `補抓並匯出`，預期用目前書源抓缺失章節，寫入快取後匯出。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 匯出入口 | `features/book_detail/book_detail_page.dart` / `_handleExport()` |
| 匯出服務 | `core/services/export_book_service.dart` / `exportToTxt()` |
| 線上補抓 | `core/services/export_book_service.dart` / `_resolveReadableSource()` |
| 本地正文 | `core/services/local_book_service.dart` / `getContent()` |
| 正文快取 DAO | `core/database/dao/reader_chapter_content_dao.dart` |

常見故障定位：

- 匯出檔缺章：先看 dialog 選項，若選「只匯出已快取」這是預期行為。
- 補抓並匯出失敗：檢查目前書源是否存在且 `isReadingEnabledByRuntime`。
- TXT 檔名錯誤：檢查 `ExportBookService` 對非法檔名字元的替換。
- 本地書匯出空內容：檢查原始本地檔是否仍存在，或 `LocalBookService.getContent()` 是否可讀。

### D8 / D11 / D12 / D25 單本正文與快取管理

入口鏈路：

```text
BookDetailPage 本書快取卡片 / menu 快取狀態 / 清理
  -> BookDetailProvider.refreshCacheStatus()
  -> ReaderChapterContentDao.getEntriesByBookUrls()
  -> BookCoverStorageService.getBookAssetSize()

清理快取
  -> BookDetailProvider.clearBookCache(target)
  -> ReaderChapterContentStore.deleteStoredContentForBook()
  -> BookCoverStorageService.deleteBookAssets()
```

手動驗證：

1. 進入詳情頁，觀察 `本書快取` 卡片。
2. 預期顯示正文 `已快取章節/總章節`、正文大小、封面大小、最近快取時間。
3. 點快取卡片 refresh icon，預期數據刷新且 loading icon 正常恢復。
4. AppBar 選單點 `快取狀態 / 清理`。
5. 預期 dialog 顯示已快取章節、正文大小、封面快取、總大小、最近快取。
6. 分別點 `清除正文快取`、`清除封面快取`、`清除全部快取`。
7. 每次都應先出現確認 dialog，取消時不刪除。
8. 確認刪除後，預期 snackbar 顯示結果，快取狀態刷新。
9. AppBar 選單 `移除本書正文` 應等同清除正文快取，且需要確認。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 快取卡片 | `features/book_detail/book_detail_page.dart` / `_buildCacheStatusPanel()` |
| 快取 dialog | `features/book_detail/book_detail_page.dart` / `_showCacheDialog()` |
| 快取狀態 | `features/book_detail/book_detail_provider.dart` / `_refreshCacheStatus()` |
| 清理快取 | `features/book_detail/book_detail_provider.dart` / `clearBookCache()` |
| 正文刪除 | `features/reader/engine/reader_chapter_content_store.dart` |
| 封面資產大小 | `core/services/book_cover_storage_service.dart` / `getBookAssetSize()` |

常見故障定位：

- 已讀章節不算快取：檢查 entry 是否 `isReady` 且 `hasDisplayContent`。
- 快取大小為 0：檢查正文內容是否為空，封面資產是否已存到 book asset dir。
- 清正文後閱讀器仍顯示舊內容：可能是閱讀器記憶體狀態，重新進入閱讀器確認資料庫狀態。
- 清全部後封面仍顯示：檢查是否仍可從網路 URL 重新載入，這不代表本地封面快取未刪除。

### D9 編輯書籍資訊

入口鏈路：

```text
BookInfoHeader 書名區點擊 / AppBar menu 編輯資訊
  -> _showEditBookInfoDialog()
  -> BookDetailProvider.updateBookInfo()
  -> BookDao.upsert(book)
```

手動驗證：

1. 進入書籍詳情。
2. 點書名資訊區或 AppBar 選單 `編輯資訊`。
3. 修改書名、作者、封面、分類、自訂標籤、來源名稱、目錄 URL、簡介。
4. 點取消，預期資料不改變。
5. 再次打開並修改，點儲存。
6. 預期詳情頁立即更新，重新進入詳情頁後仍保留。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 編輯 dialog | `features/book_detail/book_detail_page.dart` / `_showEditBookInfoDialog()` |
| 更新資料 | `features/book_detail/book_detail_provider.dart` / `updateBookInfo()` |
| 書籍模型 | `core/models/book.dart` |
| 書籍 DAO | `core/database/dao/book_dao.dart` |

常見故障定位：

- 簡介顯示沒變：檢查 `intro` 與 `customIntro` 是否同步更新。
- 來源名稱空白後消失：目前空白來源名稱不覆蓋原值，檢查輸入是否真的非空。
- 封面欄位更新後沒換圖：檢查 `coverUrl`、`customCoverUrl` 與 `coverLocalPath` 優先序。

### D10 / D15 / D22 查看來源狀態、書源詳情與調試

入口鏈路：

```text
BookInfoHeader 來源文字 / 來源狀態 chip
  -> _showSourceOptions()
  -> SourceEditorPage(source)
  -> SourceDebugPage(source, debugKey: book.name)

BookDetailProvider._loadSource()
  -> BookSource.runtimeHealth
  -> sourceStatusLabel / sourceStatusDescription
```

手動驗證：

1. 進入線上書籍詳情。
2. Header 應顯示來源名稱與來源狀態 chip。
3. 長按或 hover chip 時，預期 tooltip 說明來源狀態。
4. 點來源名稱，預期 dialog 顯示狀態、描述與來源 URL。
5. 點 `詳情`，預期進入書源編輯頁。
6. 返回後點 `調試`，預期進入書源調試頁，debug key 為書名。
7. 將書源停用或改成不可閱讀健康狀態後再進詳情，預期顯示警示與換源入口。
8. 本地書來源狀態應顯示 `本地`。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 來源顯示 | `features/book_detail/widgets/book_info_header.dart` |
| 來源 dialog | `features/book_detail/book_detail_page.dart` / `_showSourceOptions()` |
| 來源狀態 | `features/book_detail/book_detail_provider.dart` / `sourceStatusLabel` |
| 書源健康 | `core/models/source/book_source_logic.dart` |
| 書源編輯 | `features/source_manager/source_editor_page.dart` |
| 書源調試 | `features/source_manager/source_debug_page.dart` |

常見故障定位：

- 狀態永遠健康：檢查 `BookSource.runtimeHealth` 與 `isReadingEnabledByRuntime`。
- 點詳情無反應：檢查 `provider.currentSource` 是否為 null。
- 線上書顯示找不到書源：檢查 `book.origin` 是否能對上 `BookSource.bookSourceUrl`。

### D13 預下載章節

入口鏈路：

```text
BookDetailPage menu 預下載章節
  -> _showDownloadSheet()
  -> BookDetailProvider.queueDownload*
  -> DownloadService.addDownloadTask(book, chapters)
```

手動驗證：

1. 進入線上書籍詳情，確認書源可閱讀且目錄不為空。
2. AppBar 選單點 `預下載章節`。
3. 分別測試：
   - `從目前章節起下載到結尾`
   - `從目前章節起下載後 10 章`
   - `從目前章節起下載後 50 章`
   - `下載全書`
   - `下載全部未下載章節`
   - `指定章節範圍`
4. 預期成功時顯示 `已加入背景下載佇列，共 N 章`。
5. 對本地書測試，預期提示 `這本書已經在裝置內，不需要背景下載。`
6. 對失效或找不到書源的書測試，預期阻擋並提示原因。
7. 進入下載管理頁，預期可看到對應任務。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 預下載 UI | `features/book_detail/book_detail_page.dart` / `_showDownloadSheet()` |
| 下載到結尾 | `features/book_detail/book_detail_provider.dart` / `queueDownloadFromCurrent()` |
| 後 N 章 | `features/book_detail/book_detail_provider.dart` / `queueDownloadNext()` |
| 指定範圍 | `features/book_detail/book_detail_provider.dart` / `queueDownloadRange()` |
| 全部未下載 | `features/book_detail/book_detail_provider.dart` / `queueDownloadMissing()` |
| 下載任務 | `core/services/download_service.dart` |

常見故障定位：

- 加入佇列數量不對：UI 輸入是 1-based，provider 內部轉 0-based。
- 本地書被加入下載：檢查 `supportsBackgroundDownload` 是否排除 `book.origin == local`。
- 全部未下載仍重複下載已快取章節：檢查 `storedChapterIndices()` 使用的 `origin/bookUrl/chapterUrl` 是否一致。

### D14 單本書更新檢查

入口鏈路：

```text
BookDetailPage menu 檢查更新
  -> BookDetailProvider.checkForUpdates()
  -> BookSourceService.getBookInfo()
  -> BookSourceService.getChapterList()
  -> ChapterDao.deleteByBook() / insertChapters()
  -> BookDao.upsert(book)
```

手動驗證：

1. 進入線上書籍詳情。
2. AppBar 選單點 `檢查更新`。
3. 若沒有新章節，預期提示 `已是最新，總共 N 章`。
4. 若書源目錄新增章節，預期提示 `發現 N 個新章節`。
5. 詳情頁目錄數量、最新章節、快取狀態總章節數應同步更新。
6. 返回書架，預期書架更新狀態刷新。
7. 對本地書測試，預期提示 `本地書不需要檢查線上更新`。
8. 對不可閱讀書源測試，預期提示檢查失敗並保存 `lastCheckTime`。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| UI 入口 | `features/book_detail/book_detail_page.dart` / `_handleCheckUpdate()` |
| 更新檢查 | `features/book_detail/book_detail_provider.dart` / `checkForUpdates()` |
| 詳情解析 | `core/services/book_source_service.dart` / `getBookInfo()` |
| 目錄解析 | `core/services/book_source_service.dart` / `getChapterList()` |
| 書架刷新 | `core/engine/app_event_bus.dart` |

常見故障定位：

- 新章節數不準：檢查更新前 `oldTotal` 來源是否正確，章節 index 是否重設。
- 檢查後章節 bookUrl 錯誤：`checkForUpdates()` 會把章節 `bookUrl` 改回原書 URL。
- 檢查失敗沒有記錄時間：檢查 catch 分支是否更新 `book.lastCheckTime`。

### D18-D23 詳情初始化、既有資料與本地書

入口鏈路：

```text
BookDetailPage(book or searchBook)
  -> BookDetailProvider(AggregatedSearchBook)
  -> _init()
  -> BookDao.getByUrl()
  -> _loadSource()
  -> _loadBookInfo()
  -> _loadChapters()
  -> _refreshCacheStatus()
```

手動驗證：

1. 從搜尋結果進詳情，預期 `SearchBook` 可轉為 `Book` 並顯示基本資料。
2. 從書架進同一本書，預期使用資料庫既有書籍資料與 `isInBookshelf` 狀態。
3. 刪除本地章節資料後進線上詳情，若書源可閱讀，預期重新載入目錄。
4. 將書源規則改壞，預期詳情不直接崩潰，盡量用既有資訊顯示。
5. 本地書進詳情，預期來源狀態顯示 `本地`，預下載被阻擋。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 詳情初始化 | `features/book_detail/book_detail_provider.dart` / `_init()` |
| 搜尋書轉換 | `features/book_detail/book_detail_provider.dart` / constructor |
| 詳情載入 | `features/book_detail/book_detail_provider.dart` / `_loadBookInfo()` |
| 目錄載入 | `features/book_detail/book_detail_provider.dart` / `_loadChapters()` |
| 本地書判斷 | `core/models/book.dart` / `isLocal` |

常見故障定位：

- 搜尋結果進詳情後 DB 沒資料：檢查 `_init()` 是否在 existing null 時 `BookDao.upsert()`。
- 詳情載入失敗後 tocUrl 空：catch 分支會用 `bookUrl` 作 fallback，檢查是否被改掉。
- 本地書被當線上書：檢查 `book.origin` 是否為 `local`。

### D30 書架刷新事件

手動驗證：

1. 在詳情頁加入書架、移出書架、換源或檢查更新。
2. 返回書架。
3. 預期書架列表、最新章節與書籍狀態已刷新。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 詳情事件發送 | `features/book_detail/book_detail_provider.dart` |
| 事件 bus | `core/engine/app_event_bus.dart` |
| 書架刷新 | `features/bookshelf/bookshelf_provider.dart` |

常見故障定位：

- 詳情操作成功但書架沒變：檢查是否漏 fire `AppEventBus.upBookshelf`。
- 書架收到事件但資料舊：檢查 DAO 寫入是否在 fire event 前完成。

### D31 已移除：閱讀器來源 fallback sheet

決策：

- `ReaderSourceFallbackSheet` 未接入主線閱讀器流程，容易和正式換源 / 詳情頁換源造成兩套來源切換邏輯。
- 已刪除 `lib/features/reader/widgets/reader_source_fallback_sheet.dart`。
- D 系列只保留詳情頁換源；閱讀器 runtime 來源切換若要驗證，應放到閱讀器系列文件。

手動驗證：

1. 使用 `rg "ReaderSourceFallbackSheet|reader_source_fallback_sheet" lib test`。
2. 預期沒有任何引用。
3. 閱讀器正文失敗時，不應跳出這個已刪除的 fallback sheet。
4. 需要切換整本來源時，從書籍詳情頁使用 D4 換源。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 已刪除檔案 | `features/reader/widgets/reader_source_fallback_sheet.dart` |
| 正式詳情換源 | `features/book_detail/widgets/change_source_sheet.dart` |
| 詳情換源狀態 | `features/book_detail/book_detail_provider.dart` / `changeSource()` |

常見故障定位：

- 仍看到 fallback UI：檢查是否有未清除的舊 build 或分支檔案。
- 有人重新引用刪除檔案：`flutter analyze` 應會直接報 missing import。

## 常見故障定位總表

| 問題 | 優先檢查 |
| --- | --- |
| 詳情頁一直 loading | `BookDetailProvider._init()` 是否卡在書源請求；看 AppLog 的詳情/目錄載入錯誤 |
| 詳情頁章節空白 | `ChapterDao.getByBook()`、`BookSourceService.getChapterList()`、書源 `isReadingEnabledByRuntime` |
| 加入書架成功但書架不顯示 | `Book.isInBookshelf`、`BookDao.upsert()`、`AppEventBus.upBookshelf` |
| 換源後資料錯亂 | `Book.migrateTo()`、章節 `bookUrl/index` 正規化、`ChapterDao.deleteByBook()` |
| 預下載無效 | `supportsBackgroundDownload`、`_prepareStorageDownloadQueue()`、`DownloadService.addDownloadTask()` |
| 快取數量不準 | `ReaderChapterContentDao.getEntriesByBookUrls()`、entry `origin/bookUrl/chapterIndex/status` |
| 匯出缺章 | `cacheStatus.missingChapterCount`、匯出 dialog 選項、`fetchMissingRemote` |
| 封面沒有更新 | `customCoverUrl`、`customCoverLocalPath`、`BookCoverStorageService.ensureDisplayCoverStored()` |
| 來源狀態不對 | `BookSource.runtimeHealth`、`sourceStatusLabel`、`sourceStatusDescription` |
| 本地書被當線上書處理 | `Book.isLocal`、`book.origin == local` |

## 回歸測試建議

每次修改 D 系列檔案後至少跑：

```bash
flutter analyze
flutter test test/features/book_detail
```

若修改換源 provider、下載服務、正文快取或閱讀器入口，再加跑：

```bash
flutter test test/features/reader/change_source_provider_test.dart \
  test/features/reader/change_source_item_test.dart \
  test/features/reader/reader_source_switch_facade_test.dart \
  test/features/reader/reader_source_switch_runtime_test.dart
```

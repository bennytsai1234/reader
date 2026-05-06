# 線上書籍內容流程

## 目前責任

- 將書源規則、網路請求、登入檢查、redirect 檢查與 parser 串成線上小說的搜尋、發現、書籍詳情、目錄與正文流程。
- 提供 feature 層可呼叫的 `BookSourceService` 與底層 `WebBook` 靜態流程。

## 範圍

- Service facade：`lib/core/services/book_source_service.dart`。
- Web pipeline：`lib/core/engine/web_book/web_book_service.dart`。
- Parser：`book_list_parser.dart`、`book_info_parser.dart`、`chapter_list_parser.dart`、`content_parser.dart`。
- Network/error helpers：`lib/core/network/`、`lib/core/exception/app_exception.dart`、`SourceVerificationService`。
- 測試：`test/core/engine/web_book_service_test.dart`、`test/web_book_service_test.dart` 與 parser integration tests。

## 依賴與影響

- 依賴書源規則解析、`NetworkService`/Dio、cookie、source runtime health、chapter DAO 與 content storage。
- 下游影響搜尋、發現、書籍詳情、閱讀器 runtime、下載、source debug 與 source validation。
- 目錄與正文流程的 key、URL、chapter index 會影響閱讀進度與快取命中。

## 關鍵流程

- 搜尋：`SearchModel` 呼叫 `WebBook.searchBookAwait()`，透過 searchUrl 與 `BookListParser` 產生結果。
- 發現：探索頁或 explore show 呼叫 `WebBook.exploreBookAwait()`，以 explore URL 解析書籍列表。
- 詳情：`BookDetailProvider` 透過 `BookSourceService.getBookInfo()` 取得書名、作者、封面、intro 與 tocUrl。
- 目錄：`getChapterListAwait()` 支援初始 toc、nextUrls、多頁目錄與章節去重。
- 正文：`getContentAwait()` 支援正文抓取、多頁正文、下一章 URL 與內容 parser。

## 常見修改起點

- 線上書籍某階段抓不到：先判斷是 search、explore、detail、toc 或 content，再看 `WebBook` 對應方法。
- source health 或登入問題：先看 `BookSource` runtime health、`SourceVerificationService` 與 browser verification。
- 目錄頁數或正文多頁：先看 `getChapterListAwait()` 或 `getContentAwait()` 的翻頁與上限。
- 解析結果欄位不對：回到 web book parser 與 rule engine。

## 修改路線

- 修改線上流程時，先用 parser/service test 固定資料，再跑會觸發該流程的 provider/widget test。
- 改 network 錯誤或 login 檢查時，同步 source debug、browser verification 與 validation 工具的顯示。
- 改章節 URL 或 content key 時，同步閱讀器、下載、content cache 與 progress。

## 已知風險

- 目錄與正文都有翻頁上限，修正漏頁時需避免無限迴圈。
- 登入檢查與 redirect 檢查會在多個流程重複出現，行為不一致會造成 debug 困難。
- 線上流程和 parser/JS engine 耦合高，不能只看 UI symptom。

## 參考備註

- Legado 對應區域是 `model/webBook/WebBook.kt`、`BookList.kt`、`BookInfo.kt`、`BookChapterList.kt`、`BookContent.kt`。
- 本專案已經保留搜尋、發現、詳情、目錄、正文核心流程；不要引入 Legado 的非小說流程作為新需求。

## 不要做

- 不要在 feature provider 內重寫 web book 抓取流程。
- 不要為了單一來源放寬全域 parser 行為而不加測試。
- 不要把 source 驗證、登入與 cookie 問題藏成一般 network failure。

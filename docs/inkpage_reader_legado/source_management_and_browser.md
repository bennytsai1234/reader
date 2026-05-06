# 書源管理與瀏覽驗證

## 目前責任

- 管理書源匯入、預覽、儲存、編輯、分組、排序、啟停、批次檢查、debug 與 source subscription。
- 提供 WebView/browser 流程處理登入、驗證碼、cookie 回寫與需要人工互動的 source verification。

## 範圍

- 書源管理 UI/provider：`lib/features/source_manager/`。
- Browser：`lib/features/browser/`。
- Source services：`CheckSourceService`、`SourceDebugService`、`SourceUpdateService`、`SourceVerificationService`、`CookieStore`、`WebViewDataService`。
- Import helper：`SourceImportService` 與 `widgets/import_preview_dialog.dart`。
- 測試：`test/features/source_manager/`、`test/features/browser/`、`test/core/services/source_verification_service_test.dart`。

## 依賴與影響

- 依賴 `BookSourceDao`、`NetworkService`、`AnalyzeUrl`、browser WebView、cookie storage、source rule models 與 source health。
- 下游影響搜尋、發現、閱讀、source validation、書籍詳情與換源。
- 書源匯入會過濾非小說文字來源，這是本專案縮減功能邊界的一部分。

## 關鍵流程

- 匯入：JSON 或 URL payload 轉成 `BookSource`，分類為可匯入與不支援來源，再做預覽與 insert/update。
- 管理：provider 讀取 source parts，提供分組、搜尋、排序、批次操作與健康檢查報告。
- 編輯：source editor 分區編輯 basic、search、explore、book info、toc、content 等 rule。
- Debug/檢查：source debug 與 check service 對規則、搜尋或發現進行驗證。
- Browser 驗證：`BrowserProvider` 建立可用 URL/header/cookie，WebView 成功後回寫 cookie 或重新抓取內容。

## 常見修改起點

- 書源匯入或預覽問題：先看 `SourceImportService`。
- 管理頁列表、排序、篩選、批次工具列：先看 `SourceManagerProvider` 與 source manager widgets。
- 編輯表單欄位：先看 `source_editor_page.dart`、`dynamic_form_builder.dart` 與 `views/source_edit_*.dart`。
- 驗證碼、登入、cookie：先看 `BrowserProvider`、`SourceVerificationCoordinator` 與 `CookieStore`。
- 書源健康檢查：先看 `CheckSourceService` 與 source manager check UI。

## 修改路線

- 新增書源欄位時，同步 model、database、editor form、import/export、preview、debug 與 tests。
- 改驗證流程時，同步 WebView header/cookie、source verification result 與重新抓取策略。
- 改不支援來源過濾時，先確認是否違反「專注小說閱讀」的產品邊界。

## 已知風險

- 匯入在 isolate 解析 payload，物件需保持可序列化。
- Cookie 與驗證流程牽涉 WebView、Dio 與 source rules，容易出現只在真實網站發生的問題。
- 書源檢查可能觸發大量 network/request，需要注意併發與 UI 進度。

## 參考備註

- Legado 對應區域是 `ui/book/source/*`、`ui/login`、`ui/browser`、`model/CheckSource.kt` 與 source import 相關類別。
- 參考管理與 debug 概念即可；不需要補齊 Legado 的所有 source 類型與分享入口。

## 不要做

- 不要讓非小說來源成為本專案的新增對齊目標。
- 不要把 browser 驗證結果只存在 UI state，cookie 或 refetch 結果需要回到 service/storage。
- 不要讓 source manager 直接承擔 parser engine 的責任。

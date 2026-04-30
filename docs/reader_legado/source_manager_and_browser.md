# Source Manager And Browser

## Reader 現況

- 書源管理：`lib/features/source_manager`
- 瀏覽器 / 驗證：`lib/features/browser`
- 代表檔案：
  - `lib/features/source_manager/source_manager_page.dart`
  - `lib/features/source_manager/source_editor_page.dart`
  - `lib/features/source_manager/source_debug_page.dart`
  - `lib/features/browser/browser_page.dart`
  - `lib/features/browser/source_verification_coordinator.dart`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/database`、`lib/core/models/book_source*.dart`、`lib/core/services/book_source_service.dart`、`lib/core/services/check_source_service.dart`、`lib/core/services/source_debug_service.dart`、`lib/core/services/source_update_service.dart`、`lib/core/services/webview_data_service.dart`、`lib/core/services/source_verification_service.dart`
- 直接下游影響：`lib/features/search`、`lib/features/explore`、`lib/features/book_detail/source`、`lib/features/settings`，以及所有依賴登入、驗證碼、Cookie 與書源規則的流程

## Legado 對照

- 書源主區：`legado/app/src/main/java/io/legado/app/ui/book/source`
- 書源除錯：`legado/app/src/main/java/io/legado/app/ui/book/source/debug`
- 書源編輯：`legado/app/src/main/java/io/legado/app/ui/book/source/edit`
- 書源管理：`legado/app/src/main/java/io/legado/app/ui/book/source/manage`
- Browser / Login：`legado/app/src/main/java/io/legado/app/ui/browser`、`legado/app/src/main/java/io/legado/app/ui/login`
- 規則模型與解析：`legado/app/src/main/java/io/legado/app/model/analyzeRule`

## 可借鏡的方向

- 書源清單、編輯器、除錯器如何拆分
- 規則輸入 UI 與實際解析執行如何隔開
- 來源驗證、登入、驗證碼、Cookie 回寫如何與主流程解耦

## 不要做的事

- 不為了模仿 `legado` 增加新的書源類型
- 不把 WebView 功能擴張成一般瀏覽器產品

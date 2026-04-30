# App Shell

## Reader 現況

- 主入口：`lib/main.dart`
- 啟動流程：`lib/features/welcome/splash_page.dart` 負責必要初始化與錯誤恢復
- 主導航殼層：`lib/features/welcome/main_page.dart` 負責主分頁狀態，並在首幀後啟動延後初始化
- Provider 組裝：`lib/app_providers.dart`

## Reader 上下游依賴

- 直接上游依賴：`lib/core/di`、`lib/core/services/default_data.dart`、`lib/features/settings/settings_provider.dart`
- 直接下游影響：`lib/features/bookshelf`、`lib/features/explore`、`lib/features/settings`，以及所有依賴全域 Provider 與啟動初始化的功能頁

## Legado 對照

- 主導航：`legado/app/src/main/java/io/legado/app/ui/main`
- 啟動頁：`legado/app/src/main/java/io/legado/app/ui/welcome`
- 代表檔案：
  - `legado/app/src/main/java/io/legado/app/ui/main/MainActivity.kt`
  - `legado/app/src/main/java/io/legado/app/ui/main/MainViewModel.kt`

## 可借鏡的方向

- 首頁主導航如何分頁與維持狀態
- 啟動流程如何分成必要初始化與延後初始化
- 啟動失敗時如何讓畫面可恢復，而不是直接卡死

## 不要做的事

- 不為了模仿 `legado` 重做整個首頁資訊架構
- 不把與主導航無關的功能硬塞進啟動流程

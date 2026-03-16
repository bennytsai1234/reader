# Legado Reader (Flutter 版)

這是一個受 [Legado (閱讀)](https://github.com/gedoor/legado) 啟發的跨平台小說閱讀器專案，使用 Flutter 開發。

## ⚠️ 重要聲明：開發初期階段

本專案目前處於 **極早期開發階段 (Early Alpha)**：
- **大量 Bug 存在**：核心解析引擎與 UI 仍有許多未完善之處。
- **手動確認需求**：目前許多規則解析結果需要開發者手動進行驗證與調試。
- **驗證環境**：目前主要在 **Android** 平台上進行功能驗證與測試。

## 🎯 發展目標

雖然目前以 Android 驗證為主，但本專案的最終目標是成為一個 **iOS/Android 通用** 的小說閱讀器，補足 iOS 平台上自定義書源閱讀器的空缺。

## 🛠 已實作功能 (修復中)

- [x] **規則解析引擎**：支援 JsonPath, XPath, CSS 選擇器。
- [x] **動態規則處理**：支援 `@get`, `@put`, `{{js}}` 及 `{$.path}` 嵌套語法。
- [x] **音訊支援**：基礎的背景播放與音訊管理。
- [x] **跨平台架構**：已完成 Android 端的編譯環境適配。

## 🚀 快速開始

### 環境需求
- Flutter SDK: `^3.29.1`
- Android SDK: `36` (Compile/Target)

### 構建指令
```bash
# 獲取相依套件
flutter pub get

# 執行測試 (強烈建議在修改後執行)
flutter test

# 構建 Debug APK
flutter build apk --debug

# 構建 Release APK
flutter build apk --release
```

## 🧪 測試說明

專案包含完整的單元測試與整合測試，位於 `test/` 目錄。
目前所有 **83 個核心測試** 均已通過，涵蓋了規則切分、JsonPath 解析與變數傳遞邏輯。

---
**GitHub 倉庫**: [https://github.com/bennytsai1234/-Legado.git](https://github.com/bennytsai1234/-Legado.git)

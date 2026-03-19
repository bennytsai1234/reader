# Legado Reader (Flutter)

基於 Flutter 開發的高自訂化跨平台網文/電子書閱讀器，靈感來自於開源專案 Legado (閱讀)。專案支援網頁書源解析、本地書籍導入、智慧 TTS 聽書等功能，致力於提供純粹、流暢且具備高度擴充性的閱讀體驗。

---

## ✨ 目前核心功能 (Current Features)

*   **📖 基本與本機閱讀器**
    *   支援穩定的本地書籍加載閱讀，具備純粹且極致流暢的閱讀核心。
    *   提供「無縫捲動 (Scroll)」與「經典平移 (Slide)」雙重原生翻頁模式，畫面絲滑無掉幀。
*   **🎧 智能 TTS 有聲書**
    *   支援背景播放與系統級媒體控制。
    *   具備智慧化段落切分與預取機制，保證朗讀與內容完美同步。
*   **🌏 繁簡體中文切換**
    *   內建高效能文本轉換，支援即時切換繁體中文與簡體中文，適應不同來源與閱讀習慣。

## 🚀 未來加強與驗證計畫 (Roadmap & Planned Features)

*   **🎨 高度客製化排版與視覺**
    *   持續發展並驗證自訂字體、行距、背景顏色主題，以及 EPUB 等多樣式渲染支持。
*   **🕷️ 書源平台高度客製化與解析強化**
    *   發展並測試高自訂性書源平台銜接，包括 HTML、JSONPath、XPath 引擎整合。
    *   持續驗證 JavaScript 沙盒 (`flutter_js`) 在動態加解密書源上的執行穩定度。
*   **🛡️ 反爬蟲穿透與防護**
    *   強化 Headless WebView 與全局 Cookie 接管機制，針對 Cloudflare 等高防護站點進行繞過驗證。
*   **🧹 內容淨化與管理**
    *   建立完整的正則替換過濾流程，消除或替換錯別字與網站廣告。

---

## 🛠️ 技術棧 (Tech Stack)

專案採用時下最新的 Flutter 開發規範與生態構建：
*   **框架**: Flutter 3.29.1+
*   **架構設計**: 採用高度解耦的模組化結構 (`core` 底層邏輯 + `features` 業務模組)
*   **狀態與路由**: `provider` (響應式狀態), `event_bus` (事件驅動)
*   **依賴注入 (DI)**: `get_it` 全域單例配置
*   **資料持久化**: `drift` (建置高效能 SQLite 叢集，包含 20+ 個 DAO), `shared_preferences`
*   **網路與抓取**: `dio`, `webview_flutter`

---

## 🚀 快速開始 (Getting Started)

### 準備環境
請確保你的開發環境已經正確安裝 [Flutter SDK](https://flutter.dev/docs/get-started/install)。

### 安裝與運行
```bash
# 1. 取得專案檔案 (請先確保在專案根目錄下)
# git clone https://github.com/your-repo/legado_reader_flutter.git
# cd legado_reader_flutter

# 2. 下載依賴套件
flutter pub get

# 3. 執行程式 (需連接實體裝置或是啟動模擬器)
flutter run
```

---

## 📦 專案目錄結構 (Project Structure)

```text
lib/
├── core/                  # 核心底層封裝
│   ├── constant/          # 全域常數與列舉
│   ├── database/          # Drift 資料庫與所有 DAO 介面
│   ├── di/                # GetIt 依賴注入註冊中心
│   ├── engine/            # HTML/JSON 等書源規則解析器與 JS 沙盒
│   ├── network/           # Dio 封裝與請求攔截器
│   └── services/          # TTS、日誌與崩潰處理等背景服務
├── features/              # 獨立的模組化業務功能
│   ├── bookshelf/         # 書架與書籍分類管理
│   ├── reader/            # 核心閱讀器 (排版渲染、翻頁動畫、TTS 面板)
│   ├── source_manager/    # 書源探索與本地除錯編輯器
│   ├── settings/          # App 偏好設定
│   └── search/            # 全域搜尋與發現頁面
├── shared/                # 共用元件 (客製化 Widget、主題樣式)
├── app_providers.dart     # 全域 Provider 狀態樹佈署
└── main.dart              # App 進入點與全域初始化
```

---

## 📄 授權協議 (License)
目前版本屬於私人/開源專案維護，具體開源協議請參閱專案授權文件。

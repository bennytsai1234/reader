# 🗺️ Legado (Android) vs. Reader (iOS) 極細粒度資料夾映射地圖

本報告提供 Legado Android 原生專案與 iOS Flutter 移植專案之間的 1:1 資料夾與功能對位關係，旨在實現精確導航與邏輯對齊。

---

## 1. 核心邏輯與引擎層 (Core Engine & Logic)

| 功能分類 | Android (Legado) 資料夾路徑 | iOS (Flutter) 對應路徑 | 說明 |
| :--- | :--- | :--- | :--- |
| **數據模型** | `app/src/main/java/io/legado/app/data/entities` | `lib/core/models/` | 書籍、書源、章節等實體類別 |
| **資料庫接口** | `app/src/main/java/io/legado/app/data/dao` | `lib/core/database/dao/` | sqflite 存取層對位 Room DAO |
| **解析引擎** | `app/src/main/java/io/legado/app/help` | `lib/core/engine/` | `AnalyzeRule`, `AnalyzeUrl` 核心邏輯 |
| **JS 引擎實作**| `modules/rhino` | `lib/core/engine/script/` | JavaScript 全域物件注入與腳本執行 |
| **爬蟲調度** | `modules/book` | `lib/core/engine/web_book/` | 網路抓取與併發控制邏輯 |
| **網路請求** | `app/src/main/java/io/legado/app/help/coroutine` | `lib/core/network/` | Dio 請求、Cookie 管理與攔截器 |
| **同步服務** | `app/src/main/java/io/legado/app/model` | `lib/core/services/` | WebDAV 進度與書籍同步核心 |
| **後台任務** | `app/src/main/java/io/legado/app/service` | `lib/core/services/` | 下載、校驗源、背景檢查更新 |
| **工具箱** | `app/src/main/java/io/legado/app/utils` | `lib/core/utils/` | 字體解析、寬度計算與檔案讀取 |

## 2. 使用者介面層 (UI / Features)

| UI 模組 | Android (Legado) UI 目錄 | iOS (Flutter) Features 目錄 | 說明 |
| :--- | :--- | :--- | :--- |
| **書架主頁** | `.../ui/main/bookshelf` | `lib/features/bookshelf/` | 書架列表、分組、長按管理 |
| **全域搜尋** | `.../ui/book/search` | `lib/features/search/` | 搜尋頁面、聚合列表、精準過濾 |
| **閱讀器介面** | `.../ui/book/read` | `lib/features/reader/` | 閱讀頁面、翻頁動畫、菜單控制 |
| **閱讀控制** | `.../ui/book/read/page` | `lib/features/reader/engine/` | 文字分頁、圖片渲染核心 Widget |
| **閱讀設定** | `.../ui/book/read/config` | `lib/features/reader/widgets/settings/` | 排版、主題、翻頁模式底欄 |
| **書源管理** | `.../ui/book/source` | `lib/features/source_manager/` | 書源清單、規則編輯、校驗狀態 |
| **書源編輯** | `.../ui/book/source/edit` | `lib/features/source_manager/views/` | 搜尋、目錄、正文規則分層編輯 |
| **書籍詳情** | `.../ui/book/info` | `lib/features/book_detail/` | 書籍介紹、目錄預覽、換源介面 |
| **探索模組** | `.../ui/book/explore` | `lib/features/explore/` | 分類導航、動態加載列表 |
| **RSS 訂閱** | `.../ui/rss` | `lib/features/rss/` | RSS 列表、佈局切換、內核閱讀 |
| **替換淨化** | `.../ui/book/replace` | `lib/features/replace_rule/` | 正則替換規則管理 |
| **設定頁面** | `.../ui/main/my` | `lib/features/settings/` | 「我的」入口、備份、主題配置 |
| **紀錄/書籤** | `.../ui/readRecord` | `lib/features/read_record/` | 閱讀時長、全域書籤搜尋頁 |

## 3. 資源與設定 (Resources & Config)

| 資源類型 | Android (Legado) 路徑 | iOS (Flutter) 路徑 | 說明 |
| :--- | :--- | :--- | :--- |
| **靜態資源** | `app/src/main/assets` | `assets/` | 預設書源、字體、18+ 黑名單 |
| **UI 佈局定義** | `app/src/main/res/layout` | `lib/features/<mod>/widgets/` | XML 佈局對應到 Dart Widget 組件 |
| **選單與導航** | `app/src/main/res/menu` | `lib/features/welcome/main_page.dart` | 底部導航、右上角彈窗選單定義 |
| **全域配置** | `.../help/config/PreferKey.kt` | `lib/features/settings/settings_provider.dart` | SharedPreferences 鍵值對應 |

---

## 🛠️ 開發實踐：如何「指哪打哪」？

1. **修改邏輯**：
   - 如果 Android 修改了 `SearchViewModel.kt` 的聚合算法。
   - 立即定位到 iOS 的 `lib/features/search/search_provider.dart` 進行同步修復。

2. **修改排版**：
   - 如果 Android 在 `ContentTextView.kt` 增加了新的繪製標記。
   - 立即定位到 iOS 的 `lib/features/reader/engine/page_view_widget.dart` 更新 CustomPainter。

3. **增加配置**：
   - 如果 Android 在 `PreferKey.kt` 增加了新的開關。
   - 立即在 iOS 的 `lib/features/settings/settings_provider.dart` 增加對應變數。

---
📅 **最後更新日期**: 2026-03-15

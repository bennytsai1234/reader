# Reader 與 Legado 手動對照

更新日期：2026-04-20

這份文件已不再是舊的 source batch audit backlog，而是手動對照 `reader` 與 `legado` 現況的差異紀錄。

對照依據：

- `reader/lib/**/*`
- `legado/app/src/main/java/io/legado/app/ui/**/*`
- `legado/app/src/main/java/io/legado/app/data/**/*`

## 一句話結論

`reader` 目前不是「Flutter 版完整 `legado`」，而是：

- 在書源引擎與主要產品流上明顯參照 `legado`
- 在內容範圍上刻意收縮成小說閱讀器
- 在架構上比 `legado` 更強調資料層、引擎、閱讀器 runtime 的明確分區
- 在產品成熟度與周邊能力上仍落後 `legado`

## 對照方法

這份對照不是只看檔名，而是人工比對：

- app 入口
- 主頁結構
- 搜尋
- 探索
- 書源管理
- 閱讀器
- 資料層
- 本地書
- 明確缺席的功能線

## 1. App 入口與主頁

### legado

主入口是 `MainActivity`。

實際可見：

- 書架
- 探索
- RSS
- 我的

而且 `MainActivity` 本身處理很多 app 級流程：

- 隱私協議
- 版本提示
- 備份同步
- 自動更新書籍
- 雙擊返回
- tab reselect 行為

### reader

主入口是：

- [main.dart](/home/benny/projects/reader/lib/main.dart:1)
- [features/welcome/main_page.dart](/home/benny/projects/reader/lib/features/welcome/main_page.dart:1)

主頁目前只有：

- 書架
- 發現
- 我的

差異結論：

- `reader` 沒有 RSS tab
- `reader` 的 app root 較薄
- `reader` 的主頁產品線明顯比 `legado` 窄

## 2. 搜尋

### legado

對照檔：

- `ui/book/search/SearchActivity.kt`

可確認：

- 搜尋 scope menu
- 精準搜尋
- 歷史
- 搜尋結果列表
- 書源管理入口
- log 入口
- RecyclerView 與更完整 menu 交互

### reader

對照檔：

- [features/search/search_page.dart](/home/benny/projects/reader/lib/features/search/search_page.dart:1)
- [features/search/search_provider.dart](/home/benny/projects/reader/lib/features/search/search_provider.dart:1)

可確認：

- 全部 / 分組 / 單一書源搜尋
- 精準搜尋
- 搜尋歷史
- 搜尋進度與失敗來源提示
- 聚合來源顯示

差異結論：

- `reader` 在搜尋核心流程上已明顯對齊
- `legado` 的 Android menu 與列表交互仍更成熟
- `reader` 在類型與狀態模型上更明確

## 3. 探索

### legado

對照檔：

- `ui/main/explore/ExploreFragment.kt`

可確認：

- 探索列表
- 分組篩選
- 搜尋列
- 展開 / 收合
- 直接跳搜尋
- 編輯來源

### reader

對照檔：

- [features/explore/explore_page.dart](/home/benny/projects/reader/lib/features/explore/explore_page.dart:1)
- [features/explore/explore_provider.dart](/home/benny/projects/reader/lib/features/explore/explore_provider.dart:1)

可確認：

- 以書源為單位的 explore 入口
- 分組與搜尋
- 書源展開
- explore show page

差異結論：

- 這一塊產品流已明顯對照 `legado`
- `reader` 沒把 explore 擴成 RSS 或更泛的內容入口
- `reader` 仍更聚焦在小說閱讀導流

## 4. 書源管理

### legado

對照檔：

- `ui/book/source/manage/BookSourceActivity.kt`

可確認：

- 匯入本地 / 線上 / QR
- 分組管理
- 多種排序
- 批次操作列
- 校驗流程
- 調試
- 單源搜尋
- 來源啟用 / 探索開關

### reader

對照檔：

- [features/source_manager/source_manager_page.dart](/home/benny/projects/reader/lib/features/source_manager/source_manager_page.dart:1)
- [features/source_manager/source_manager_provider.dart](/home/benny/projects/reader/lib/features/source_manager/source_manager_provider.dart:1)
- [core/services/check_source_service.dart](/home/benny/projects/reader/lib/core/services/check_source_service.dart:1)

可確認：

- 匯入 URL / 檔案 / 剪貼簿 / QR
- 編輯、調試、單源搜尋
- 批次啟停、批次分組、批次刪除
- 校驗狀態列、結果面板、清理建議

差異結論：

- `reader` 在書源管理操作流上是目前最接近 `legado` 的區域之一
- 但底層資料治理還沒完全對齊，因為 health 與 check state 仍是過渡設計
- `legado` 這塊成熟度仍更高

## 5. 閱讀器

### legado

對照檔：

- `ui/book/read/ReadBookActivity.kt`
- `ui/book/read/page/*`
- `ui/book/read/config/*`

可確認：

- Activity 本體很大
- 閱讀器周邊工具與 config dialog 很完整
- 與 Android 系統、硬體、全文搜尋、更多工具頁整合更深

### reader

對照檔：

- [features/reader/runtime/read_book_controller.dart](/home/benny/projects/reader/lib/features/reader/runtime/read_book_controller.dart:1)
- [features/reader/view/read_view_runtime.dart](/home/benny/projects/reader/lib/features/reader/view/read_view_runtime.dart:1)
- `features/reader/runtime/*.dart`
- `features/reader/engine/*.dart`

可確認：

- 閱讀器主控從頁面層下沉到 runtime controller
- 有明確的 restore / progress / navigation / display / tts 子域
- slide / scroll 兩種正式模式
- 有閱讀失敗換源恢復

差異結論：

- `reader` 在架構上比 `legado` 更乾淨
- `legado` 在產品能力與周邊整合上更完整
- `reader` 還沒收完 mixin 殘留與 controller 體積問題

## 6. 資料層

### legado

從 `app/data/dao`、`app/data/entities` 可看出它有自己的資料模型與 DAO 體系。

### reader

由 [app_database.dart](/home/benny/projects/reader/lib/core/database/app_database.dart:1) 可直接確認：

- 20 張表
- 20 個 DAO
- Drift schema version 8

差異結論：

- `reader` 資料層比 `legado` 更小、更集中
- RSS 資料線已被正式清掉
- 書源治理資料還沒正規化，是目前資料層最明顯缺口

## 7. 本地書

### legado

`ui/book/import/local` 與相關 model/helper 可看出本地書與 Android 檔案流較完整。

### reader

從 [local_book_formats.dart](/home/benny/projects/reader/lib/core/local_book/local_book_formats.dart:1) 可直接確認目前只支援：

- TXT
- EPUB
- UMD

差異結論：

- `reader` 有本地書主線
- 但不應誤寫成已完整對齊 `legado` 的本地格式能力

## 8. 明確缺席的功能線

以下是從目錄與程式碼都能明確確認的差異：

### legado 有，reader 沒有整條產品線

- RSS
- 多種主頁 / 書架 style
- 更完整的 manga / audio / 多媒體內容線
- 大量 Android-only widget、dialog、檔案與系統工具頁

### reader 刻意保留但簡化

- 探索
- 書源管理
- 本地書
- 備份還原
- 閱讀器設定

## 9. 哪些地方是「閹割」，哪些地方是「重構」

### 屬於刻意閹割

- RSS 整線不做
- 多媒體內容不做
- Android-only 深度系統能力不做
- 不追求把 `legado` 所有工具頁搬完

### 屬於重新設計

- 閱讀器 runtime 拆分
- parser / JS / Web 書源集中到 `core/engine`
- Drift + DAO 明確成為資料真源
- provider 作為頁面協調層，而不是資料真源

### 屬於仍未收完

- 書源 health 與校驗結果資料落點
- WebView / login recovery
- rule 級錯誤診斷
- 閱讀器周邊交互收尾
- 測試環境可信度

## 10. 最終判斷

如果要用一句準確的話描述 `reader` 和 `legado` 的關係，應該寫成：

> `reader` 是一個以 `legado` 為行為與產品流參考、但在內容範圍上明顯縮減、在架構上重新切分的 Flutter 小說閱讀器。

這句話同時包含三件事：

1. 它不是從零發明規則系統。
2. 它不是完整複刻。
3. 它也不是單純的 UI 殼。

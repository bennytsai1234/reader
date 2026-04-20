# 當前優先級

更新日期：2026-04-20

這份 roadmap 不沿用舊版里程碑寫法，只根據目前程式碼、`flutter analyze`、`flutter test` 與手動對照 `legado` 的結果排序。

## 一句話結論

`reader` 現在最缺的不是新功能，而是把已經存在的小說閱讀主線收成一套更乾淨、更可預測的系統。

真正的優先級是：

1. 測試可信度
2. 書源狀態正規化
3. 書源引擎診斷與 recovery
4. 閱讀器交互與 runtime 收尾
5. 文件與程式描述對齊

## 現在已經站住的能力

### 已可視為主線成立

- 書架、書籍詳情、搜尋、探索、閱讀主鏈可用
- Drift 資料層與 DAO 架構已成立
- 書源 parser / JS / Web 書源子系統已存在且有大量測試
- 閱讀器 runtime 有清楚內核與測試護欄
- 本地書匯入至少有 TXT / EPUB / UMD 三條真路徑

### 不能誇大成已完成的部分

- 書源 health 仍是過渡實作
- source check 結果沒有正式持久化
- QuickJS 測試環境仍依賴 wrapper
- WebView / login / anti-bot recovery 還不夠可預測
- 閱讀器仍有一些交互與殘留 UI 未收乾淨

## P0

### P0-1：讓測試綠燈真正可信

目前現實：

- `flutter test` 在目前工作區可以通過
- 但有多個 QuickJS / VM 相關 skip
- `test_helper.dart` 明確允許 QuickJS 缺件時跳過部分測試

這代表：

- 目前 full suite 不是無條件可信
- 書源 JS 能力仍會受本機環境影響

完成標準：

- QuickJS 測試策略清楚且穩定
- 一般開發流程不需要猜哪個命令才是真的綠燈
- skip 的數量與原因被刻意控制，而不是自然放過

### P0-2：把 `flutter analyze` 收到全綠

目前我實跑看到的問題包括：

- `WillPopScope` 已過時
- `BuildContext` 跨 async gap 風險
- 未引用死碼
- 少量 lint 細節

這些不是大 bug，但會直接反映出基礎品質沒有收完。

## P1

### P1-1：把書源狀態從 `group/comment` 過渡態拉出來

目前真相：

- `CheckSourceService` 明寫「以 group/comment 持久化校驗結果」
- `BookSources` 表沒有正式 health 欄位
- UI 和 runtime health 仍要靠 tag/comment 推導

這會造成：

- 狀態語義不乾淨
- 使用者分組與系統分組混在一起
- 難以做持久化排序、篩選、歷史、統計

完成標準：

- health state 有正式欄位或獨立表
- UI 不再依賴臨時 tag 技巧
- 搜尋池、閱讀可用性、清理建議共用同一份正式資料

### P1-2：把最後一次校驗結果落地

目前 `lastReport` 只存在 service memory。

完成標準：

- 至少保存每個來源最近一次：
  - 校驗時間
  - 失敗階段
  - 摘要訊息
  - cleanup/quarantine 判斷

## P2

### P2-1：把 engine 錯誤從黑盒拉到 rule 級

目前 parser parity 已經很多，但仍缺：

- 哪條 rule 出錯
- 哪個 URL 出錯
- 哪個階段出錯

這使得 source debug、UI 提示、使用者回報都還得猜。

完成標準：

- 失敗訊息能對齊 stage / rule / URL
- source debug 與閱讀器恢復卡片不再只是 generic message

### P2-2：補 WebView / login recovery

和 `legado` 相比，這是 `reader` 最明顯還沒成熟的區塊之一。

需要補的不是更多站點特例，而是：

- recovery 路徑
- headless / fallback 行為
- 測試護欄

## P3

### P3-1：閱讀器交互收尾

當前缺口：

- 返回交互還沒跟上新的 Flutter/Android back 模型
- 有殘留但未接線的亮度 widget
- `ReadBookController` 與 mixin 鏈仍偏重

這一層不是要重寫閱讀器，而是收掉明顯的產品邊角。

### P3-2：清理 feature 內的歷史殘件

例子包括：

- 未引用方法
- 半成品 widget
- 舊命名與新命名並存
- provider 內的臨時註解式實作

## 明確不做

根據目前程式碼與產品邊界，以下不應成為主線：

- RSS 線重建
- 把 `legado` 所有 Android 工具頁搬來 Flutter
- 多媒體閱讀器產品線
- 第二套狀態管理
- 第二套資料層抽象
- 以掃更多書源取代修正既有結構

## 和 legado 的策略關係

`legado` 在這個 repo 中應該扮演的是：

- 書源 compatibility spec
- 產品流與操作設計參考
- 差異比對基準

它不應再扮演：

- 功能清單的直接來源
- 所有 Android 細節都要照搬的模板

## 判斷有沒有走對

如果下一輪改動能同時做到下面幾件事，就算方向正確：

- 文件比以前更貼近真實程式碼
- `flutter analyze` 變乾淨
- QuickJS 相關測試更可信
- 書源狀態不再依賴 group/comment 技巧
- 閱讀器與書源失敗訊息更可推理

# 閱讀器 Runtime

這份文件描述 `features/reader` 目前在 `main` 上的真實結構。

## 入口

- Provider 別名：`lib/features/reader/reader_provider.dart`
- 頁面殼：`lib/features/reader/reader_page.dart`
- 主控制器：`lib/features/reader/runtime/read_book_controller.dart`
- View runtime：`lib/features/reader/view/read_view_runtime.dart`

`ReaderProvider` 目前只是 `ReadBookController` 的薄封裝，真正的閱讀期狀態都在 controller 與 runtime 子域。

## 核心位置語義

閱讀器目前已統一 durable location：

- `ReaderLocation(chapterIndex, charOffset)`

也就是：

- 章節索引
- 章內字元偏移

這套語義會貫穿：

- restore
- repaginate
- scroll / slide 切換
- exit progress
- source switch 後重定位

頁碼與 scroll offset 都只是執行期投影，不是 durable 真源。

## 分層

### 1. Controller / Facade 層

`ReadBookController` 負責閱讀頁的高層協調：

- 設定與 UI state 接線
- session / content / viewport runtime 組裝
- bookmark、加書架、章節切換、退出流程
- 對頁面殼暴露可用狀態

Provider mixin 目前保留：

- `ReaderSettingsMixin`
- `ReaderContentFacadeMixin`
- `ReaderAutoPageMixin`
- `ReaderTtsMixin`
- `ReaderBatteryMixin`

其中 `ReaderContentFacadeMixin` 已不再是 content lifecycle owner，只是 facade 入口。

### 2. Session / Restore / Progress

主要檔案：

- `reader_session_coordinator.dart`
- `reader_session_runtime.dart`
- `reader_session_facade.dart`
- `reader_progress_store.dart`
- `reader_progress_coordinator.dart`
- `reader_restore_coordinator.dart`

這層負責：

- session location
- visible location
- durable progress
- restore token / pending restore
- exit progress persistence

### 3. Content Lifecycle

主要檔案：

- `reader_content_runtime_owner.dart`
- `reader_content_lifecycle_runtime.dart`
- `reader_content_pipeline.dart`
- `engine/chapter_content_manager.dart`
- `engine/reader_chapter_content_loader.dart`

這層負責：

- 章節正文載入
- 分頁快取
- preload / warmup
- slide window
- pinned target / deferred recenter

### 4. Viewport Runtime

主要檔案：

- `reader_runtime_controller.dart`
- `reader_viewport_runtime.dart`
- `reader_viewport_lifecycle_runtime.dart`
- `reader_viewport_execution_bridge.dart`
- `reader_page_viewport_bridge.dart`
- `reader_viewport_mailbox.dart`
- `read_view_runtime.dart`
- `view/delegate/page_mode_delegate.dart`
- `view/delegate/scroll_mode_delegate.dart`

這層負責：

- scroll / slide 的執行期行為
- mode switch
- viewport command
- controller reset / pending jump
- view size 變更與 repaginate gating

## 其他子域

### 朗讀與自動翻頁

- `read_aloud_controller.dart`
- `reader_auto_page_coordinator.dart`
- `reader_tts_follow_coordinator.dart`

### 顯示與頁碼投影

- `reader_display_coordinator.dart`
- `reader_page_factory.dart`
- `runtime/models/reader_chapter.dart`
- `engine/chapter_position_resolver.dart`

### 換源

- `reader_source_switch_facade.dart`
- `reader_source_switch_runtime.dart`

## 目前頁面殼的責任

`ReaderPage` 現在只保留頁面殼職責：

- `PageController` / `SlidePageController` 實體生命週期
- Menu、drawer、settings sheet 接線
- `ReaderPageViewportBridge` 與 page shell 互動

核心內容與位置語義不再直接堆在 widget state。

## 真實行為契約

### restore

- 以 `chapterIndex + charOffset` 還原
- restore 期間不應把臨時 visible state 誤寫成正式進度

### repaginate

- 字級 / 行距 / 段距 / 縮排等設定改動後，仍以 durable location 對回新頁面

### mode switch

- `scroll` / `slide` 切換時，語義上應保持同一個 `charOffset`

### source switch

- 切換來源後，仍以同一個 durable location 重新落回目標章節

## 對應測試

閱讀器目前有完整的 feature test 集合，至少包含：

- `test/features/reader/reader_runtime_flow_test.dart`
- `test/features/reader/read_book_controller_test.dart`
- `test/features/reader/reader_runtime_controller_test.dart`
- `test/features/reader/reader_content_lifecycle_runtime_test.dart`
- `test/features/reader/reader_content_pipeline_test.dart`
- `test/features/reader/reader_viewport_runtime_test.dart`
- `test/features/reader/reader_session_runtime_test.dart`
- `test/features/reader/reader_source_switch_runtime_test.dart`

最低驗證基線：

```bash
flutter analyze
flutter test test/features/reader
```

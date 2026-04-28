# Reader Recovery Option 3: Rebuild Reader

## 不建議採用

完全重做看起來乾淨，但目前不是最佳選擇。新版已經有可用的 engine/runtime 基礎，問題主要是遷移未收斂、progress/restore/viewport 邊界不清，以及 DB 升級風險。這些問題重做也必須面對。

## 什麼情況才需要重做

只有在以下條件成立時，才值得重做：

- `LayoutEngine` 無法穩定產生可驗證的 line/page geometry。
- `ReaderRuntime` 無法成為單一狀態真源。
- scroll 與 slide 的行為契約需要完全不同的資料模型。
- 現有主線已經無法透過分階段重構測試保護。

目前觀察不到這些條件全部成立。

## 重做的風險

- 時間成本高。
- 很容易再次忽略 DB migration。
- 很容易再次把 restore/flush 當最後才補的功能。
- 沒有舊行為保護時，體感回歸會更多。
- 章節載入、排版、scroll 高度補償、TTS follow、source switch 都要重做。

## 如果仍要重做

必須先寫規格與測試，不要先寫 UI。

建議順序：

1. DB migration spec。
2. Reader location / anchor spec。
3. Content repository spec。
4. Layout geometry spec。
5. Progress store spec。
6. Runtime state machine spec。
7. Slide viewport spec。
8. Scroll viewport spec。
9. Settings repaginate spec。
10. Source switch spec。

## 新架構最小核心

```text
ReaderDocumentRepository
  - ensureChapters()
  - loadChapterContent()

ReaderLayoutRepository
  - layoutChapter()
  - mapCharOffsetToGeometry()
  - mapGeometryToCharOffset()

ReaderSessionRuntime
  - open(target)
  - jump(location)
  - applySettings(spec)
  - switchMode(mode)
  - commitVisibleAnchor(anchor)

ReaderProgressStore
  - schedule(location, anchor?)
  - flush()
  - drainOnExit()

ReaderViewport
  - render(presentation)
  - emit viewport intents
```

## 必須先定義的不變量

- durable progress 永遠是 `chapterIndex + charOffset`。
- `ReaderAnchor` 只能加速或精準 restore，不可取代 durable progress。
- placeholder/error/loading 不可保存成 progress。
- layout signature 不匹配時，page/local offset snapshot 失效。
- content hash 不匹配時，page/local offset snapshot 失效。
- flush 必須 latest-wins 且 drain 到沒有 pending。
- mode switch 不可以透過舊 page index 還原。

## 重做驗收門檻

重做版本不應在以下全部通過前接進主線：

- 0.2.28 DB migration 測試。
- progress active flush race 測試。
- scroll restore 非 0 offset 測試。
- slide/scroll mode switch round trip 測試。
- settings repaginate preserve location 測試。
- source switch preserve location 測試。
- 本地 TXT 與遠端章節內容測試。
- widget smoke 測試：ReaderPage 能顯示正文，不是只有 loading。

## 最終判斷

重做只適合在重構現有版本失敗後啟動。現在更好的做法是採用 `reader_recovery_02_refactor_current.md`，把現有 runtime 收斂到一個可測、可恢復、可升級的主線。


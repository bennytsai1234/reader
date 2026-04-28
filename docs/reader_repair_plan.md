# Reader Repair Plan

日期：2026-04-28

## 開發前提

目前最新 `reader` 視為全新 app 開發，不以舊 app / 舊 DB 升級相容作為阻塞項。每次更新可刪除 app 並重新開始，所以這份計劃只處理「新 reader 要怎麼做穩」。

舊版 `reader-0.2.28` 只作為行為參考，不作為回退目標。

## 核心決策

閱讀位置改成三個值：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

白話意思：

- `chapterIndex`：第幾章。
- `charOffset`：章內第幾個字，這是主要閱讀進度。
- `visualOffsetPx`：scroll 模式恢復時的畫面微調位移，單位是 px。

`visualOffsetPx` 不應是章節內的大型總位移，也不應是新的 page index。它只表示：

```text
恢復時，讓 charOffset 對應的那一行，距離閱讀內容區頂部多少 px。
```

slide 模式不需要這個微調，保存：

```text
ReaderLocation(chapterIndex, charOffset, 0)
```

scroll 模式需要它，保存：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

## 為什麼需要第三個值

只存：

```text
chapterIndex + charOffset
```

可以知道「讀到哪個字」，但不知道「這個字離開前在畫面哪個位置」。scroll 模式恢復時，如果只把那個字捲到頂部，使用者看到的位置會和退出前有落差。

加上 `visualOffsetPx` 後，恢復流程變成：

```text
1. 用 chapterIndex 找章節。
2. 用 charOffset 找到對應文字行。
3. 用 visualOffsetPx 把那一行放回離開前接近的位置。
```

這樣 scroll 恢復會比單純 `chapterIndex + charOffset` 更準，但又不需要保存龐大的章內 scroll offset。

## visualOffsetPx 怎麼算

scroll 模式退出、背景、或需要保存進度時：

1. 取閱讀內容區的 anchor 線，建議是內容區頂部往下 16 到 32 px。
2. 找到這條 anchor 線附近的第一條穩定可見文字行。
3. 保存該文字行的：
   - `chapterIndex`
   - `startCharOffset`
   - `visualOffsetPx`

其中：

```text
visualOffsetPx = lineTopOnScreen - readableContentTop
```

例子：

```text
readableContentTop = 72
lineTopOnScreen = 94
visualOffsetPx = 22
```

保存：

```text
ReaderLocation(
  chapterIndex: 12,
  charOffset: 3456,
  visualOffsetPx: 22,
)
```

建議限制：

```text
visualOffsetPx >= 0
visualOffsetPx <= 120
```

如果計算出負數、NaN、無限大、或太大的值，就回退到 `0`。這個值只做小範圍視覺微調，不應承擔完整 scroll 定位。

## scroll 開書怎麼用

scroll 模式開書恢復：

```text
1. 載入 chapterIndex 對應章節。
2. layout 出行與頁面。
3. 找到 charOffset 對應文字行的章內 localY。
4. 計算目標 scroll：

targetScrollY =
  chapterBaseY
  + charLocalY
  - visualOffsetPx
  - readableContentTop
```

白話講：

```text
先找到那個字，再把畫面往上一點點，讓它回到離開前差不多的位置。
```

如果 `visualOffsetPx == 0`，就退化成一般 `chapterIndex + charOffset` 恢復。

## slide 模式怎麼用

slide 模式不使用視覺 offset。

保存：

```text
ReaderLocation(chapterIndex, charOffset, 0)
```

恢復：

```text
1. 用 chapterIndex 載入章節。
2. layout 出 pages。
3. 用 charOffset 找到對應 page。
4. 顯示該 page。
```

slide 不應用舊 page index 作主進度，因為字級、行距、螢幕尺寸變了，page index 會變。

## 要修改的主要地方

### 1. ReaderLocation

目前 `ReaderLocation` 只有：

```text
chapterIndex
charOffset
```

要改成：

```text
chapterIndex
charOffset
visualOffsetPx
```

要求：

- `visualOffsetPx` 預設為 `0`。
- normalize 時 clamp 到合理範圍。
- equality / hashCode / copyWith 都包含這個欄位。
- runtime 內所有位置傳遞都用同一個 `ReaderLocation`。

### 2. Book / DB

因為這是全新 app baseline，可以直接調整 fresh schema。

要保存三個位置值：

```text
books.chapterIndex
books.charOffset
books.visualOffsetPx
```

如果不想新增獨立欄位，也可以短期存在 `readerAnchorJson`，但本計劃推薦新增明確欄位，因為這三個值是 reader 的核心進度資料，不應藏在 JSON 裡。

`readerAnchorJson` 後續可以先保留但不作為主線必需資料。

### 3. Progress

`ReaderProgressController` 要負責保存完整三元位置：

```text
chapterIndex
charOffset
visualOffsetPx
```

修復重點：

- debounce 只保存最後一次位置。
- active flush 期間又收到新位置時，flush 結束後要繼續寫最後位置。
- exit / dispose / app paused 時必須 drain pending progress。
- loading / error placeholder 不可保存成進度。

### 4. Scroll Viewport

scroll viewport 要能回報目前可視 anchor：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

它不應直接寫 DB，只回報給 runtime/progress。

需要做：

- 從目前可見行找 anchor line。
- 算 `visualOffsetPx = lineTopOnScreen - readableContentTop`。
- 保存前 clamp。
- layout 改變或章節高度從估算變成實際值時，保持 anchor 不跳。

### 5. Runtime

`ReaderRuntime` 是唯一閱讀狀態真源。

要做：

- `visibleLocation` 使用三元 `ReaderLocation`。
- `committedLocation` 使用三元 `ReaderLocation`。
- scroll 更新 visible location 時保留 `visualOffsetPx`。
- slide 更新位置時把 `visualOffsetPx` 設為 `0`。
- mode switch 時：
  - scroll -> slide：用 `chapterIndex + charOffset` 找 page，offset 歸零。
  - slide -> scroll：用 `chapterIndex + charOffset` 找行，offset 可用 `0` 或預設 anchor。

### 6. Layout / Coordinate Mapping

layout 必須能穩定提供：

```text
charOffset -> line localY
screen visible line -> charOffset
```

需要確認：

- 每條 `TextLine` 有穩定 `startCharOffset/endCharOffset`。
- title-only line 不作為正文進度 anchor。
- `charOffset` 落在頁邊界時能找對 page / line。
- 字級、行距、padding 改變後，仍能用 `charOffset` 找回合理行。

### 7. Content

content 負責把章節正文準備好。

需要穩定：

- 章節列表。
- 正文載入。
- 本地 TXT / 遠端書源。
- 替換規則。
- 繁簡轉換。
- 分段。

content 改變時，舊的 visual offset 仍可保留為小範圍視覺修正，但不能相信舊 page index。

## 主要流程

### scroll 退出保存

```text
使用者正在 scroll
 -> viewport 找目前 anchor line
 -> 算 chapterIndex
 -> 算 charOffset
 -> 算 visualOffsetPx
 -> runtime 更新 visibleLocation
 -> progress debounce 保存
 -> 退出 / 背景時 flush
```

### scroll 開書恢復

```text
開書
 -> 讀取 Book.chapterIndex / charOffset / visualOffsetPx
 -> runtime 載入章節
 -> content 載入正文
 -> layout 排版
 -> charOffset 找到 line localY
 -> viewport scroll 到 targetScrollY
```

### slide 退出保存

```text
使用者翻到某頁
 -> runtime 知道 current page start charOffset
 -> 保存 ReaderLocation(chapterIndex, charOffset, 0)
```

### slide 開書恢復

```text
開書
 -> 讀取 chapterIndex / charOffset
 -> layout
 -> charOffset 找 page
 -> 顯示 page
```

## 驗收條件

### scroll

- scroll 到章節中段，退出再進，視覺位置接近退出前。
- 同一章內保存的 `visualOffsetPx` 是小數值，不是章節總 scroll offset。
- app paused 後重開，最後位置不丟。
- 快速滑動後立刻退出，保存最後可視位置。
- loading/error placeholder 不保存進度。

### slide

- slide 翻頁後退出再進，回到同一頁或同一 charOffset 對應頁。
- slide 保存時 `visualOffsetPx == 0`。
- 改字級後，用 `charOffset` 重新找到合理 page。

### mode switch

- scroll -> slide 不丟 `chapterIndex + charOffset`。
- slide -> scroll 可回到同一段文字附近。
- mode switch 不依賴舊 page index。

### progress

- debounce 期間多次更新，只保存最後一次。
- DB 寫入中收到新位置，最後位置仍會被寫出。
- dispose / exit / lifecycle flush 都能 drain pending progress。

## 不做的事

- 不回退到 0.2.28。
- 不以舊 DB migration 作阻塞。
- 不把 page index 作為主進度。
- 不把大型章內 scroll offset 作為主進度。
- 不讓 viewport 直接寫 DB。


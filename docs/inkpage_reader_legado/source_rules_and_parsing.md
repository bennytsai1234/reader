# 書源規則與解析引擎

## 目前責任

- 解讀 Legado-style 書源規則，支援 URL 分析、HTML/JSON/文字解析、regex、CSS、XPath、JSONPath、JS rule 與部分相容工具。
- 將書源規則模型轉成可用於搜尋、發現、書籍詳情、目錄與正文抓取的解析行為。

## 範圍

- 規則入口：`lib/core/engine/analyze_rule.dart`、`lib/core/engine/analyze_url.dart`、`lib/core/engine/rule_analyzer.dart`。
- Parser：`lib/core/engine/parsers/`。
- JS：`lib/core/engine/js/`。
- Web book parser：`lib/core/engine/web_book/*_parser.dart`。
- Rule models：`lib/core/models/source/`、`lib/core/models/book_source.dart`、`lib/core/models/rule_data_interface.dart`。
- 測試：`test/core/engine/`、`test/core/engine/js/`、`test/core/engine/parsers/`。

## 依賴與影響

- 依賴 `dio`、HTML/XML parser、CSS selector、XPath、JSONPath、`flutter_js`、encoding/crypto utils 與 network/cookie 支援。
- 下游影響搜尋、發現、書籍詳情、目錄、正文、書源 debug、source validation 與 QuickJS 測試。
- Parser 相容性改動通常會同時影響多個書源流程，不只單一頁面。

## 關鍵流程

- `AnalyzeUrl` 將書源 URL rule 轉成實際 request、method、header、body 與變數。
- `AnalyzeRule` 對目前內容套用 rule，並依內容型態選用 XPath、CSS、JSONPath、regex 或 JS。
- `RuleAnalyzer` 處理規則字串切分、range、match 等語法。
- Web book parser 將 rule 結果轉成 `SearchBook`、`Book`、`BookChapter` 或正文內容。
- JS extension 提供規則腳本需要的加解密、網路、字串、字型與檔案能力。

## 常見修改起點

- URL、header、POST、變數、page/key 行為：先看 `AnalyzeUrl`。
- rule string 切分與基礎語法：先看 `RuleAnalyzer` 與 `analyze_rule/`。
- 某種 parser 結果不對：先看 `parsers/analyze_by_*.dart`。
- JS rule 或 QuickJS 相容：先看 `core/engine/js/` 與 QuickJS wrapper scripts。
- 搜尋/詳情/目錄/正文解析錯：先看 `core/engine/web_book/*_parser.dart`，再回到 `AnalyzeRule`。

## 修改路線

- 修 parser 時，先用最小 rule test 固定輸入輸出，再確認 web book flow 是否受影響。
- 新增 Legado rule 相容時，先確認本專案現有小說閱讀流程會用到；不要為未支援功能新增通用負擔。
- JS extension 改動要搭配 QuickJS/JS 測試，不只跑一般 Flutter tests。

## 已知風險

- JS/FFI 無法隨意跨 isolate，web book flow 已有註解說解析不放到 isolate。
- Parser 相容性通常是多來源行為，單一 fixture 通過不代表所有來源穩定。
- Regex、XPath 與 CSS fallback 可能造成同一 rule 在不同內容型態下行為差異。

## 參考備註

- Legado 對應區域是 `model/analyzeRule`、`data/entities/rule` 與 `model/webBook` parser 流程。
- 只參考小說書源規則、搜尋、發現、詳情、目錄與正文需要的相容行為。
- RSS、漫畫、字典與其他 Legado rule extensions 不在本 atlas 對齊範圍。

## 不要做

- 不要把規則 parser 當成單一 feature 的私有工具修改；它是 shared engine。
- 不要新增未被 reader 現有流程使用的 Legado rule 功能。
- 不要用 ad hoc 字串處理取代已存在的 parser 或 analyzer。

# CHANGELOG

這份檔案只保留高可信度的里程碑摘要。

完整逐版內容請看：

- GitHub Releases
- `release-notes/`

## 0.2.16 — 2026-04-21

- 修正 `Build Release Artifacts` workflow，tag 釋出時會先同步最新 `main`，再回寫 `pubspec.yaml` 版本
- 成功發佈 `v0.2.16`，Android 與 iOS release artifacts 均由 CI 產生

## 0.2.15 — 2026-04-21

- 閱讀器核心重構正式落地：
  - durable location 統一為 `chapterIndex + charOffset`
  - content lifecycle / session / viewport runtime 分層
  - `ReadBookController` 收斂為 facade / coordinator 角色
  - reader 測試擴充為完整 runtime / flow / lifecycle coverage

## 更早版本

請直接查：

- <https://github.com/bennytsai1234/reader/releases>
- `release-notes/`

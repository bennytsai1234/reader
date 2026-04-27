# CHANGELOG

這份檔案只保留高可信度的里程碑摘要。完整逐版內容請看 GitHub Releases 與 `release-notes/`。

## 0.2.31 - 2026-04-27

- 重寫根目錄與 `docs/` 文件，使架構、閱讀器 runtime、資料庫 schema、CI 與 release 流程對齊目前 `main`。
- 移除過時的 reader next-stage / controller decomposition 階段稿。
- 文件明確標示資料庫已是 schema version `1`，閱讀器主線是 `ReaderPage -> ReaderRuntime -> ChapterRepository/PageResolver -> Viewport`。
- 更新 GitHub workflow notes 與 issue template 文字。

## 0.2.30 - 2026-04-27

- 重置 reader database schema 為新架構初始版本 `1`。
- 移除舊版相容 migration 與舊 durable 欄位 fallback。
- 閱讀進度收斂為 `chapterIndex + charOffset`。
- 修正 line-first 閱讀器在章節導航、章節滑桿、上一章/下一章與 slide 跨章時的定位邊界。

## 0.2.29 - 2026-04-26

- 閱讀器底層改成 line-first 模型。
- 正文取得流程收斂為 storage-first。
- 新增 `ReaderChapterContents` storage 與 reader content store。
- 移除舊 reader temp chapter cache，下載、儲存、閱讀使用同一條資料通道。

## 0.2.28 - 2026-04-26

- 修正 scroll mode 重開後閱讀位置累積偏移。
- scroll 進度 anchor 改為 viewport top anchor。
- 退出閱讀器時保存目前可見 scroll 位置。

## 0.2.16 - 2026-04-21

- 修正 `Build Release Artifacts` workflow，tag 釋出時先同步最新 `main`，再回寫 `pubspec.yaml` 版本。
- Android 與 iOS release artifacts 改由 CI 產生。

## 更早版本

請查：

- <https://github.com/bennytsai1234/reader/releases>
- `release-notes/`

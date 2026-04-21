# 文檔索引

這個目錄只保留和 `main` 目前實際狀態對得上的文件。

## 保留原則

- 只寫能由程式碼、資料結構、CI 或檔案目錄驗證的事
- 不保留 roadmap、handoff、audit backlog、實驗計畫稿
- 如果某份文件失真，就刪掉或重寫，不保留「之後再補」的殘稿

## 目前保留的文件

- [architecture.md](architecture.md)
  - repo 的模組邊界、核心資料流與 feature 分工

- [reader_runtime.md](reader_runtime.md)
  - 閱讀器目前的 runtime 結構、責任切分與位置語義

- [reader_spec.md](reader_spec.md)
  - 閱讀器目前真實可驗證的功能規格與非目標

- [DATABASE.md](DATABASE.md)
  - Drift schema version、資料庫檔案位置、資料表分組與 migration 節點

- [release.md](release.md)
  - `main`、tag、GitHub Actions 與 release artifacts 的真實釋出流程

## 建議閱讀順序

1. [../README.md](../README.md)
2. [architecture.md](architecture.md)
3. [reader_runtime.md](reader_runtime.md)
4. [reader_spec.md](reader_spec.md)
5. [DATABASE.md](DATABASE.md)
6. [release.md](release.md)

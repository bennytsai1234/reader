# 釋出流程

這份文件描述目前 repo 真正使用中的 release 流程。

## 工作流

### `dart.yml`

觸發：

- push 到 `main`
- pull request 到 `main`

執行：

- `flutter analyze`
- `tool/flutter_test_with_quickjs.sh`

### `build-release.yml`

觸發：

- `workflow_dispatch`
- push tag：`v*`

執行：

1. 以 tag 名稱推導版本號 `X.Y.Z`
2. checkout 最新 `main`
3. 把 `pubspec.yaml` 改成 `X.Y.Z+<github.run_number>`
4. commit 並回推到 `main`
5. 建 Android split APK
6. 建 iOS unsigned IPA
7. 發佈 GitHub Release

## 本地發版步驟

### 1. 確認 `main` 乾淨

```bash
git checkout main
git pull --ff-only origin main
git status
```

### 2. 跑最低驗證

```bash
flutter analyze
tool/flutter_test_with_quickjs.sh
```

如果本次改了閱讀器核心，另外跑：

```bash
flutter test test/features/reader
```

### 3. 可選：補 release notes

若要提供自訂 release 內容，建立：

```text
release-notes/vX.Y.Z.md
```

若沒有這個檔案，GitHub Release 會退回 auto notes。

### 4. 建 tag 並推送

```bash
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

## 產物

Release workflow 目前會產出：

- Android split APK
  - `app-arm64-v8a-release.apk`
  - `app-armeabi-v7a-release.apk`
  - `app-x86_64-release.apk`
- iOS unsigned IPA
  - `inkpage-ios-unsigned.ipa`

## 版本同步規則

tag 是 release 的語意版本來源：

- tag：`v0.2.16`
- `pubspec.yaml`：`0.2.16+31`

其中 build number 使用 `github.run_number`。

因此每次 release 完成後，`main` 會多一個自動版本回寫 commit。  
本地若在 release 後落後遠端，直接：

```bash
git pull --ff-only origin main
```

## 常見注意事項

- 不要手動上傳產物替代 workflow
- 不要假設 rerun 舊 tag run 會自動吃到新 workflow；修 workflow 後要發新 tag
- 若 release 失敗，先看 `Build Release Artifacts` 的 `Inject Version from Tag`

# 釋出流程

這份文件描述目前 repo 使用中的 CI 與 release 流程。

## CI

### `.github/workflows/dart.yml`

觸發：

- push 到 `main`
- pull request 到 `main`

執行：

```bash
flutter pub get
flutter analyze
flutter test --reporter compact
```

### `.github/workflows/build-release.yml`

觸發：

- `workflow_dispatch`
- push tag：`v*`

工作：

1. tag 觸發時從 tag 名稱推導版本 `X.Y.Z`。
2. checkout `main`。
3. 把 `pubspec.yaml` 改成 `X.Y.Z+<github.run_number>`。
4. commit 並 push 回 `main`。
5. 建 Android split APK。
6. 建 iOS unsigned IPA。
7. tag 觸發時發佈 GitHub Release。

## Android 簽章

Android release workflow 需要固定 keystore secrets：

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

缺少任一 secret 時 Android release job 會失敗。固定簽章 key 是為了讓後續 APK 可覆蓋安裝舊版本。

## iOS 產物

iOS workflow 目前使用：

```bash
flutter build ios --release --no-codesign
```

然後把 `Runner.app` 包成 unsigned IPA。這個產物不含 Apple signing certificate 或 provisioning profile，不能直接上架 App Store。

## 本地發版前檢查

1. 確認在 `main` 且工作樹乾淨。
2. 拉最新：

```bash
git pull --ff-only origin main
```

3. 跑最低驗證：

```bash
flutter analyze
flutter test
```

4. 若修改 Drift schema / DAO，先跑：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. 若修改閱讀器核心，至少加跑：

```bash
flutter test test/features/reader
```

## Release notes

自訂 release notes 放在：

```text
release-notes/vX.Y.Z.md
```

若檔案不存在，GitHub Release job 會使用 auto generated notes。

## 建 tag

```bash
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

tag 是語意版本來源。workflow 會把 `pubspec.yaml` 回寫成：

```text
version: X.Y.Z+<github.run_number>
```

release 完成後，本地通常需要再拉一次 `main`，取得 workflow 產生的版本回寫 commit。

## Release artifacts

Android：

- `app-arm64-v8a-release.apk`
- `app-armeabi-v7a-release.apk`
- `app-x86_64-release.apk`

iOS：

- `inkpage-ios-unsigned.ipa`

## 注意事項

- 不要手動上傳產物替代 workflow。
- 不要手動改 `pubspec.yaml` 當作正式 release 來源；release version 來自 tag。
- 修 workflow 後不要假設 rerun 舊 tag 一定吃到新 workflow；必要時發新 tag。
- 若 release 失敗，先看 `Inject Version from Tag` 與 Android signing secrets。

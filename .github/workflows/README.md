# GitHub Actions Build Notes

目前有兩條主要 workflow：

- `dart.yml`：CI 驗證
- `build-release.yml`：release artifacts 與 GitHub Release

## CI

`dart.yml` 在 push / pull request 到 `main` 時執行：

```bash
flutter pub get
flutter analyze
flutter test --reporter compact
```

## Release Workflow

`build-release.yml` 可手動執行，也會在 push `v*` tag 時執行。

tag release 流程：

1. 從 tag `vX.Y.Z` 推導版本 `X.Y.Z`。
2. checkout `main`。
3. 回寫 `pubspec.yaml` 為 `X.Y.Z+<github.run_number>`。
4. commit 並 push 回 `main`。
5. 建 Android split APK。
6. 建 iOS unsigned IPA。
7. 發佈 GitHub Release。

## Android 簽章

Android release 必須使用固定 release keystore。請在 repository secrets 設定：

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

`ANDROID_KEYSTORE_BASE64` 可用下列方式產生：

```bash
base64 -w 0 your-release-key.jks
```

建立 release key 範例：

```bash
keytool -genkeypair \
  -v \
  -keystore your-release-key.jks \
  -alias inkpage \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

本地 release build 可在 `android/key.properties` 填：

```properties
storeFile=/abs/path/to/your-release-key.jks
storePassword=...
keyAlias=...
keyPassword=...
```

一旦正式使用某把 release key，後續版本應固定使用同一把 key，否則 Android 會視為不同簽章而無法覆蓋安裝。

## Artifacts

Android：

- `app-arm64-v8a-release.apk`
- `app-armeabi-v7a-release.apk`
- `app-x86_64-release.apk`

iOS：

- `inkpage-ios-unsigned.ipa`

## iOS 限制

iOS workflow 目前沒有 Apple signing certificate 或 provisioning profile，產物是：

```bash
flutter build ios --release --no-codesign
```

再將 `Runner.app` 包成 unsigned IPA。這種 IPA 適合交給側載工具後續處理，不能直接上架 App Store。

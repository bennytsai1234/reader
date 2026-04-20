# GitHub Actions Build Notes

這個專案目前提供一條自動建置工作流：

- Android：輸出 `app-release.apk`
- iOS：輸出 `unsigned .ipa`

## Android 簽章

如果你希望新版本 APK 可以直接覆蓋安裝舊版本，**每次 release 都必須使用同一把簽章 key**。

目前 workflow 已改成要求固定的 Android release keystore，不再使用 runner 臨時生成的 debug keystore。請先在 GitHub repository secrets 設定：

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

`ANDROID_KEYSTORE_BASE64` 的產生方式可以用：

```bash
base64 -w 0 your-release-key.jks
```

如果你還沒有 release keystore，可以先建立一把：

```bash
keytool -genkeypair \
  -v \
  -keystore your-release-key.jks \
  -alias inkpage \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

本地若要用同一把 key 打 release，也可以在 `android/key.properties` 填：

```properties
storeFile=/abs/path/to/your-release-key.jks
storePassword=...
keyAlias=...
keyPassword=...
```

注意：一旦你決定了正式 release keystore，就應該長期固定使用它。若你之前已經安裝過不同簽章的 APK，**第一次切到這把正式 key 時仍然需要先卸載一次**；之後只要保持同一把 key，後續版本就能正常覆蓋安裝。

## 觸發方式

- 手動：`Actions` -> `Build Release Artifacts` -> `Run workflow`
- 自動發版：push `v*` tag，例如：

```bash
git tag v0.1.0
git push origin v0.1.0
```

## iOS 限制

目前 workflow 沒有接 Apple 開發者憑證與 provisioning profile，所以 iOS 產物是：

- `flutter build ios --release --no-codesign`
- 再將 `Runner.app` 包成 unsigned `.ipa`

也就是未簽章版本。  
這種 `.ipa` 適合拿去給 AltStore / 類似側載工具處理，但不能直接上架 App Store。

如果之後要讓 GitHub Actions 直接產出可安裝的簽章版 iOS 包，需要另外配置：

- Apple Developer 帳號
- signing certificate
- provisioning profile
- GitHub Secrets

# Voyeur - Flutter 專案啟動與啟動教學

歡迎使用 **Voyeur**！此專案已從原生 SwiftUI 遷移至 **Flutter**，現在支援 iOS, Android, Web 與 macOS。

## 📋 準備工具

在開始之前，請確保你的 Mac 已安裝：
- **Flutter SDK** (已由 Homebrew 安裝)
- **CocoaPods** (iOS 開發必備，若未安裝請執行 `brew install cocoapods`)
- **Xcode** (若要開發 iPhone 版本則必須安裝)

---

## 🚀 執行專案

### 1. 啟動 Web 或 macOS 版 (無需 Xcode)

在終端機中進入專案目錄，執行以下指令：

```bash
# 啟動 Web (Chrome)
flutter run -d chrome

# 啟動 macOS 桌面版
flutter run -d macos
```

### 2. 啟動 Android 版

確保已連接 Android 裝置或開啟模擬器，然後執行：

```bash
flutter run -d android
```

---

## 📲 部署至實體 iPhone 裝置

由於 iOS 開發環境較特殊，請遵循以下步驟：

1. **安裝 Xcode**: 請從 App Store 或 Apple 開發者官網重新下載安裝 Xcode。
2. **安裝實體裝置工具**:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. **設定 Signing**:
   - 開啟專案中的 `ios/Runner.xcworkspace`。
   - 在 **Runner** -> **Signing & Capabilities** 中登入你的 Apple ID 並選擇 Team。
4. **執行**:
   - 連接 iPhone 到 Mac。
   - 執行 `flutter run -d <iphone_id>` 或直接在 Xcode 中點擊 「▶️ Run」。
5. **信任開發者**: 在 iPhone 上前往 **設定 -> 一般 -> VPN 與裝置管理**，信任你的開發者帳號。

---

## 🛠 專案架構

- **lib/services/app_config.dart**: 管理 API 連結與資源位址。
- **lib/services/video_cache_manager.dart**: 處理影片本地緩存。
- **lib/viewmodels/dance_viewmodel.dart**: 核心業務邏輯與影片探測。
- **lib/views/**: 所有 UI 視圖（包含水滴動畫與卡片滑動）。

---

## 💡 開發小技巧

- **Hot Reload**: 在終端機執行時按下 `r` 鍵可立即看到修改結果，無需重新編譯。
- **清理緩存**: 若遇到套件問題，可執行 `flutter clean` 後再 `flutter pub get`。

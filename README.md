# Voyeur - Flutter 專案啟動與啟動教學

歡迎使用 **Voyeur**！此專案已從原生 SwiftUI 遷移至 **Flutter**，現在支援 iOS, Android, Web 與 macOS。

## 📋 準備工具

在開始之前，請確保你的 Mac 已安裝：
- **Flutter SDK** (已由 Homebrew 安裝)
- **CocoaPods** (iOS 開發必備，若未安裝請執行 `brew install cocoapods`)
- **Xcode** (若要開發 iPhone 版本則必須安裝)

---

## 🚀 常用開發指令

在開發過程中，你可能會用到以下指令：

### 1. 基礎環境設定
```bash
# 下載專案必要的套件
flutter pub get

# (僅限 iOS/macOS) 安裝原生依賴庫
cd ios && pod install && cd ..
```

### 2. 執行專案
```bash
# 啟動 Web (Chrome)
flutter run -d chrome

# 啟動 macOS 桌面版
flutter run -d macos

# 啟動已連接的裝置 (iPhone/Android)
flutter run
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
3. **設定 iOS 依賴**:
   ```bash
   cd ios
   pod install
   cd ..
   ```
4. **設定 Signing**:
   - 開啟專案中的 `ios/Runner.xcworkspace`。
   - 在 **Runner** -> **Signing & Capabilities** 中登入你的 Apple ID 並選擇 Team。
5. **執行**:
   - 連接 iPhone 到 Mac。
   - 執行 `flutter run` 或直接在 Xcode 中點擊 「▶️ Run」。

---

## 🎥 Boomerang 特效說明

本專案實作了 **Boomerang (正序+倒序)** 的循環播放效果：

- **運作機制**: 影片下載後在背景使用 FFmpeg 進行運算，合併「正序」與「倒序」片段。
- **儲存位置**: 處理過的影片會儲存在 App 的 Cache 目錄中，檔名以 `boomerang_` 開頭。
- **初次載入**: 若影片剛下載完畢，FFmpeg 尚在運算時會先播放原始正序影片，待運算完成後，下次進入該卡片即會自動切換為正反連續播放。

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

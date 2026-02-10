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

### 方法一：使用 Xcode（推薦，最簡單）

1. **開啟 Xcode 專案**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **選擇你的 iPhone**:
   - 在 Xcode 頂部工具列，點擊裝置選擇器
   - 選擇你已連接的 iPhone（會顯示裝置名稱，例如「Vins 的 iPhone」）

3. **設定簽署**（首次需要）:
   - 點擊左側專案導航中的 **Runner**
   - 選擇 **Signing & Capabilities** 標籤
   - 在 **Team** 下拉選單中登入你的 Apple ID

4. **執行**:
   - 點擊左上角的 **播放按鈕 ▶️**
   - Xcode 會自動編譯並安裝到你的 iPhone

5. **信任開發者**（首次需要）:
   - 在 iPhone 上前往 **設定 → 一般 → VPN 與裝置管理**
   - 點擊你的 Apple ID，選擇「信任」

---

### 方法二：使用 Flutter CLI

1. **連接 iPhone 並確認裝置**:
   ```bash
   flutter devices
   ```
   應該會看到類似：
   ```
   iPhone 17 Pro Max (mobile) • 00008030-XXXXXXXXXXXX • ios • iOS 17.2
   ```

2. **直接執行**:
   ```bash
   # 自動選擇已連接的 iPhone
   flutter run
   
   # 或指定裝置 ID
   flutter run -d 00008030-XXXXXXXXXXXX
   ```

3. **首次部署可能需要**:
   ```bash
   cd ios
   pod install
   cd ..
   flutter run
   ```

---

### 常見問題

**Q: 提示「Developer Mode required」**  
A: iOS 16+ 需要啟用開發者模式：  
   設定 → 隱私權與安全性 → 開發者模式 → 開啟

**Q: 提示「Provisioning profile」錯誤**  
A: 在 Xcode 中重新選擇 Team 並確認簽署設定正確

**Q: Flutter 找不到我的 iPhone**  
A: 
   - 確認 iPhone 已解鎖且信任此電腦
   - 重新插拔 USB 連接線
   - 執行 `flutter doctor` 檢查環境

---

## 🎥 Boomerang 特效說明

本專案實作了 **Boomerang (正序+倒序)** 的循環播放效果：

- **運作機制**: 使用 `video_player` 的播放控制 API，影片播放到結尾後自動倒序播放回起點，形成無縫循環。
- **優點**: 
  - ✅ 不需要預先處理影片檔案
  - ✅ 不依賴 FFmpeg 等外部工具
  - ✅ 即時生效，無需等待轉檔
- **實作細節**: 監聽影片播放位置，到達結尾時使用 `seekTo()` 逐幀倒退，模擬倒序播放效果。

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

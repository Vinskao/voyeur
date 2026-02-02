# Voyeur - iOS 專案啟動與部署教學

歡迎使用 **Voyeur**！這是一個使用 SwiftUI 與 SwiftData 打造的原生 iOS 應用程式。

## 📋 準備工具
在開始之前，請確保你的 Mac 已安裝：
- **Xcode** (建議最新版本)
- **Apple ID** (用於裝置開發授權)

---

## 🚀 步驟一：啟動專案

1. **開啟專案**：
   在終端機中進入專案目錄，或直接在 Finder 中雙擊 `voyeur.xcodeproj` 檔案。
2. **等待編譯**：
   Xcode 開啟後，請等待右上方進度條完成索引與編譯準備。

---

## 🛠 專案架構與配置

### 環境變數 (Environment Variables)
你可以透過環境變數 `DANCE_VIDEO_BASE_URL` 來設定預設的影片來源 URL。
預設值為：`http://peoplesystem.tatdvsonorth.com`

**如何在 Xcode 中設定：**
1. 點擊頂部專案名稱 -> **Edit Scheme...**。
2. 選擇 **Run** -> **Arguments**。
3. 在 **Environment Variables** 點擊 `+`。
4. Name: `DANCE_VIDEO_BASE_URL`, Value: `http://你的網址...`

### 主要組件
- **AppConfig.swift**: 管理預設 URL 與環境變數。
- **DanceViewModel.swift**: 處理掃描影片與下載邏輯。
- **VideoCacheManager.swift**: 處理 iOS 檔案緩存 (Library/Caches)。
- **DanceVideoListView.swift**: 影片管理介面。

---

## 📲 部署至實體 iOS 裝置

1. 連接 iPhone 到 Mac。
2. 在 Xcode 的 **Project Navigator** 點擊最上層 `voyeur` 藍圖圖示。
3. 選擇 **TARGETS -> voyeur** -> **Signing & Capabilities**。
4. 在 **Team** 選項中登入你的 Apple ID。
5. 在裝置選擇器中選擇你的 iPhone，然後點擊 **「▶️ Run」**。
6. 在 iPhone 上前往 **設定 -> 一般 -> VPN 與裝置管理**，信任你的開發者帳號。

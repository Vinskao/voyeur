# Mac 空間清理 & 開發垃圾清理指令大全

## 🔥 Cursor 清理

### 全刪（最乾淨）

``` bash
rm -rf ~/Library/Application\ Support/Cursor
```

### 只刪資料庫（保留設定）

``` bash
rm -f ~/Library/Application\ Support/Cursor/User/globalStorage/*.vscdb*
```

------------------------------------------------------------------------

## 🔥 Android SDK 清理

### 只刪 System Images

``` bash
rm -rf ~/Library/Android/sdk/system-images
```

### 完全不用 Android（全刪）

``` bash
rm -rf ~/Library/Android
rm -rf ~/Android
```

------------------------------------------------------------------------

## 🔥 Git Repo 瘦身

### 刪除暫存 pack

``` bash
find ~/001-project -name "tmp_pack*" -delete
```

### Git 壓縮瘦身

``` bash
cd ~/001-project/EC/BFF_Extention
git gc --aggressive --prune=now
```

------------------------------------------------------------------------

## 🔥 Xcode 清理

``` bash
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport
```

------------------------------------------------------------------------

## 🔥 Angular Cache 清理

``` bash
rm -rf ~/.angular/cache
```

------------------------------------------------------------------------

## 🔥 Google Updater Cache 清理

``` bash
rm -rf ~/Library/Application\ Support/Google/GoogleUpdater/crx_cache
```

------------------------------------------------------------------------

## 💀 一鍵暴力清理（安全於多數開發環境）

``` bash
rm -rf ~/Library/Application\ Support/Cursor ~/Library/Android ~/Library/Developer/Xcode/iOS\ DeviceSupport ~/.angular/cache ~/Library/Application\ Support/Google/GoogleUpdater/crx_cache
```

------------------------------------------------------------------------

## 🚀 找大檔案指令

### 找家目錄大檔

``` bash
sudo find ~ -type f -size +300M -print0 | xargs -0 ls -lh | sort -k5 -hr | head -40
```

### 找整機大檔

``` bash
sudo find / -type f -size +500M -print0 2>/dev/null | xargs -0 ls -lh | sort -k5 -hr | head -40
```

------------------------------------------------------------------------

## ⭐ Docker 清理

``` bash
docker system prune -a -f --volumes
```

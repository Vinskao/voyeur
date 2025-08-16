# WebSocket 配置說明

## 📋 配置概覽

### ✅ 已完成的配置更新

1. **統一 WebSocket URL 配置**
   - 移除了不必要的 `WEBSOCKET_URL` 配置
   - 統一使用 `WEBSOCKET_TYMB` 作為完整的 WebSocket URL

2. **更新為本地端點**
   - **新端點**: `ws://localhost:8080/tymb/metrics`
   - **數據格式**: JSON (Spring Boot Actuator metrics)
   - **協議**: 直接 WebSocket (非 STOMP)

### 🔧 更新的文件

#### 1. `voyeur/settings.py`
```python
# WebSocket settings
WEBSOCKET_TYMB = os.getenv('WEBSOCKET_TYMB', 'ws://localhost:8080/tymb/metrics')
```

#### 2. `metrics/config.py`
```python
# WebSocket settings
WEBSOCKET_TYMB = os.getenv('WEBSOCKET_TYMB', 'ws://localhost:8080/tymb/metrics')
```

#### 3. `metrics/connect.py`
- 移除了 STOMP 相關代碼
- 更新為直接處理 JSON 格式的 metrics 數據
- 添加了自動重連機制
- 改進了錯誤處理和日誌記錄

#### 4. `.env`
```bash
WEBSOCKET_TYMB=ws://localhost:8080/tymb/metrics
```

### 📊 預期的數據格式

根據你提供的示例，WebSocket 將接收以下格式的 JSON 數據：

```json
{
  "data": {
    "http.server.requests": {
      "name": "http.server.requests",
      "baseUnit": "seconds",
      "measurements": [
        {"statistic": "COUNT", "value": 23.0},
        {"statistic": "TOTAL_TIME", "value": 0.667934708},
        {"statistic": "MAX", "value": 0.49068475}
      ],
      "availableTags": [...]
    },
    "system.cpu.usage": {
      "name": "system.cpu.usage",
      "description": "The \"recent cpu usage\" of the system",
      "measurements": [
        {"statistic": "VALUE", "value": 0.09631313131313131}
      ]
    },
    "jvm.memory.used": {...},
    "process.cpu.usage": {...},
    "jvm.threads.live": {...},
    "hikaricp.connections.active": {...}
  },
  "type": "metrics",
  "timestamp": "2025-08-16T12:51:04.161480Z"
}
```

### 🚀 測試工具

#### 1. 配置測試
```bash
python3 test_config.py
```

#### 2. 連接測試
```bash
./test_curl.sh
```

#### 3. WebSocket 客戶端測試
```bash
python3 test_websocket_client.py
```

### 📝 Jenkins 配置更新

確保 Jenkins 中的 `WEBSOCKET_TYMB` 憑證值為：
```
ws://localhost:8080/tymb/metrics
```

### 🔍 目前的狀態

- ✅ 配置已更新為本地端點
- ✅ 代碼已更新為處理 JSON 格式
- ✅ 移除了不必要的 STOMP 邏輯
- ⏳ 等待本地 Spring Boot 應用啟動
- ⏳ 需要測試實際的 WebSocket 連接

### 🎯 下一步

1. 啟動本地 Spring Boot 應用 (端口 8080)
2. 運行 WebSocket 客戶端測試
3. 驗證數據接收和存儲功能
4. 部署到生產環境並更新 Jenkins 配置

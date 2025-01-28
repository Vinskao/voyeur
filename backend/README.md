# 專案名稱

## 簡介
簡要介紹專案的目的和功能。

## 安裝

### 使用Poetry安裝
確保您已經安裝了[Poetry](https://python-poetry.org/)，然後運行以下命令來安裝專案依賴：

```bash
pip install poetry
poetry install
python3 manage.py runserver 8000
```

## 使用方法
提供一些基本的使用示例或命令，幫助用戶快速上手。

## WebSocket 客戶端流程
以下是作為 WebSocket 客戶端的基本流程：

1. 導入 WebSocket 庫
2. 創建 WebSocket 連接
3. 發送和接收消息
4. 關閉連接

### 技術細節
- **WebSocket 協議**：WebSocket 是一種在單個 TCP 連接上進行全雙工通訊的協議，適合需要即時數據傳輸的應用。
- **連接建立**：使用 `websocket` 庫的 `WebSocketApp` 類來創建連接，並指定 WebSocket 伺服器的 URL。
- **事件處理**：可以定義多個事件處理函數，例如 `on_message`、`on_error`、`on_close` 和 `on_open`，以處理不同的事件。
- **持續運行**：使用 `run_forever()` 方法保持連接持續運行，直到手動關閉。

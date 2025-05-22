# Voyeur Backend

這是一個用於收集和提供指標數據的後端服務。

## 安裝

1. 安裝 Poetry（如果尚未安裝）：
```bash
curl -sSL https://install.python-poetry.org | python3 -
```

2. 安裝項目依賴：
```bash
poetry install
```

3. 進入 Poetry shell：
```bash
poetry shell
```

## 配置

創建 `.env` 文件並設置以下環境變數：

```env
MONGODB_URI=mongodb://localhost:27017/
MONGODB_DB=voyeur
MONGODB_COLLECTION=ty_backend_metrics
WEBSOCKET_HOST=localhost
WEBSOCKET_PORT=8080
WEBSOCKET_PATH=/tymb/metrics
API_HOST=0.0.0.0
API_PORT=5000
API_DEBUG=True
```

## 運行

1. 啟動開發服務器：
```bash
poetry run python3 manage.py runserver
```

2. 使用 Daphne 啟動生產服務器：
```bash
poetry run daphne -b 0.0.0.0 -p 8000 voyeur.core.asgi:application
```

## API 端點

- `GET /api/metrics/`: 獲取所有指標數據
- `GET /api/orm_metrics/`: 獲取 ORM 相關指標
- `DELETE /api/orm_metrics/delete`: 刪除 ORM 指標數據

## WebSocket 連接

使用 wscat 測試 WebSocket 連接：
```bash
wscat -c ws://localhost:8000/ws/metrics/
```

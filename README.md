# Voyeur

這是一個用於收集和提供指標數據的後端服務。


## Setup

1. Install Poetry (if you haven't already):
```bash
curl -sSL https://install.python-poetry.org | python3 -
```

2. Install dependencies:
```bash
poetry install
poetry run python manage.py runserver
poetry run python3 manage.py runserver
poetry run python3 manage.py migrate
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

## API 端點

- `GET /api/metrics/`: 獲取所有指標數據
- `GET /api/orm_metrics/`: 獲取 ORM 相關指標
- `DELETE /api/orm_metrics/delete`: 刪除 ORM 指標數據

```
http://127.0.0.1:8000/swagger/
http://127.0.0.1:8000/swagger.json

https://peoplesystem.tatdvsonorth.com/voyeur/swagger
```
## WebSocket 連接

使用 wscat 測試 WebSocket 連接：
```bash
wscat -c ws://localhost:8000/ws/metrics/
```

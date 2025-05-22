import os
from pathlib import Path

# 基礎路徑設定
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# MongoDB 設定
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
MONGODB_DB = os.getenv('MONGODB_DB', 'voyeur')
MONGODB_COLLECTION = os.getenv('MONGODB_COLLECTION', 'ty_backend_metrics')

# WebSocket 設定
WEBSOCKET_HOST = os.getenv('WEBSOCKET_HOST', 'localhost')
WEBSOCKET_PORT = int(os.getenv('WEBSOCKET_PORT', '8080'))
WEBSOCKET_PATH = os.getenv('WEBSOCKET_PATH', '/tymb/metrics')

# API 設定
API_HOST = os.getenv('API_HOST', '0.0.0.0')
API_PORT = int(os.getenv('API_PORT', '5000'))
API_DEBUG = os.getenv('API_DEBUG', 'True').lower() == 'true' 
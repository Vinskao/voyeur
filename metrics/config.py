import os
from dotenv import load_dotenv

load_dotenv()

# MongoDB settings
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://localhost:27017/')
MONGODB_DB = os.getenv('MONGODB_DB', 'voyeur')
MONGODB_COLLECTION = os.getenv('MONGODB_COLLECTION', 'metrics')

# Redis settings
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_CUSTOM_PORT', 6379))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', None)
REDIS_QUEUE_NAME = os.getenv('REDIS_QUEUE_NAME', 'increment_queue')

# WebSocket settings - 寫死在代碼中
WEBSOCKET_TYMB = 'ws://localhost:8080/tymb/' 
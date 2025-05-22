import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# MongoDB settings
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb+srv://tianyikao:${MONGODB_PASSWORD}@palais.7t2na.mongodb.net/')
MONGODB_DB = os.getenv('MONGODB_DB', 'voyeur')
MONGODB_COLLECTION = os.getenv('MONGODB_COLLECTION', 'metrics')

# WebSocket settings
WEBSOCKET_HOST = os.getenv('WEBSOCKET_HOST', 'localhost')
WEBSOCKET_PORT = int(os.getenv('WEBSOCKET_PORT', '8080'))
WEBSOCKET_PATH = os.getenv('WEBSOCKET_PATH', '/tymb/metrics') 
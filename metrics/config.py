import os
from dotenv import load_dotenv

load_dotenv()

# MongoDB settings
MONGODB_URI = os.getenv('MONGODB_URI', 'mongodb://localhost:27017')
MONGODB_DB = os.getenv('MONGODB_DB', 'voyeur')
MONGODB_COLLECTION = os.getenv('MONGODB_COLLECTION', 'metrics')

# Redis settings
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', '6379'))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')
REDIS_QUEUE_NAME = os.getenv('REDIS_QUEUE_NAME', 'increment_queue')

# WebSocket settings
WEBSOCKET_TYMB = os.getenv('WEBSOCKET_TYMB', 'ws://localhost:8080/tymb/')

# Parse WebSocket URL to extract components
def parse_websocket_url(url):
    """Parse WebSocket URL to extract host, port, and path"""
    if url.startswith('ws://'):
        url = url[5:]  # Remove 'ws://'
    elif url.startswith('wss://'):
        url = url[6:]  # Remove 'wss://'
    
    # Split host:port and path
    if '/' in url:
        host_port, path = url.split('/', 1)
        path = '/' + path
    else:
        host_port = url
        path = '/'
    
    # Split host and port
    if ':' in host_port:
        host, port = host_port.split(':')
        port = int(port)
    else:
        host = host_port
        port = 80 if url.startswith('ws://') else 443
    
    return host, port, path

# Extract components from WEBSOCKET_TYMB
WEBSOCKET_HOST, WEBSOCKET_PORT, WEBSOCKET_PATH = parse_websocket_url(WEBSOCKET_TYMB)

# Full WebSocket URL with /metrics hardcoded
WEBSOCKET_URL = WEBSOCKET_TYMB + 'metrics' 
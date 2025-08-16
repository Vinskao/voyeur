import time
import logging
import json
import websocket
from .store import store_message_in_mongo
from .config import WEBSOCKET_TYMB

# 設置日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

up_data = []

def on_message(ws, message):
    """Handle messages received from the WebSocket server."""
    logger.info(f"Received message: {message[:200]}...")  # 只顯示前200個字符
    
    if not message.strip():
        logger.warning("Received an empty message.")
        return

    try:
        # 直接解析 JSON 格式的 metrics 數據
        data = json.loads(message)
        up_data.append(data)
        store_message_in_mongo(message)  # 儲存原始 JSON 訊息
        logger.info("Saved metrics data to MongoDB")
        
        # 顯示一些關鍵指標
        if 'data' in data and 'http.server.requests' in data['data']:
            requests = data['data']['http.server.requests']
            for measurement in requests.get('measurements', []):
                if measurement.get('statistic') == 'COUNT':
                    logger.info(f"HTTP Requests Count: {measurement.get('value', 0)}")
        
        if len(up_data) >= 10:
            logger.info(f"Received {len(up_data)} messages")
            up_data.clear()  # 清空緩存
            
    except json.JSONDecodeError as e:
        logger.error(f"Error decoding JSON message: {e}")
        logger.error(f"Raw message: {message}")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        
def on_error(ws, error):
    """Handle errors encountered during WebSocket communication."""
    logger.error(f"WebSocket Error: {error}")

def on_close(ws, close_status_code, close_msg):
    """Handle the closing of the WebSocket connection."""
    logger.info(f"WebSocket connection closed: {close_status_code} - {close_msg}")

def on_open(ws):
    """Handle the opening of the WebSocket connection."""
    logger.info("WebSocket connection opened successfully")
    websocket_url = WEBSOCKET_TYMB.rstrip('/') + '/metrics'
    logger.info(f"Connected to: {websocket_url}")

def start_websocket():
    """Start WebSocket connection to receive metrics data."""
    # 構建完整的 WebSocket URL，加上 metrics 路徑
    websocket_url = WEBSOCKET_TYMB.rstrip('/') + '/metrics'
    logger.info(f"Starting WebSocket connection to: {websocket_url}")
    
    ws = websocket.WebSocketApp(websocket_url,
                              on_open=on_open,
                              on_message=on_message,
                              on_error=on_error,
                              on_close=on_close)
    
    # 自動重連機制
    while True:
        try:
            ws.run_forever()
            logger.info("WebSocket connection lost, attempting to reconnect in 5 seconds...")
            time.sleep(5)
        except Exception as e:
            logger.error(f"WebSocket error: {e}")
            time.sleep(5) 
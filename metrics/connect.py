import time
import stomp
import logging
import json
import websocket
from .store import store_message_in_mongo
from .config import WEBSOCKET_HOST, WEBSOCKET_PORT, WEBSOCKET_URL

# 設置日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

up_data = []

def connect_metrics():
    """Connect to the STOMP server and subscribe to a topic."""
    conn = stomp.Connection([(WEBSOCKET_HOST, WEBSOCKET_PORT)])

    while True:
        try:
            conn.connect(wait=True)
            conn.subscribe(destination="/topic/metrics", id=1, ack="auto")
            logger.info("Subscribed to /topic/metrics")
            while True:
                time.sleep(1)
        except Exception as e:
            logger.error(f"WebSocket connection failed: {e}")
            time.sleep(5)  # 連線失敗時，等待 5 秒重試
            conn.disconnect()
            conn = stomp.Connection([(WEBSOCKET_HOST, WEBSOCKET_PORT)])

def on_message(ws, message):
    """Handle messages received from the WebSocket server."""
    logger.info(f"Received raw message: {message}")
    
    if not message.strip():
        logger.warning("Received an empty message.")
        return

    try:
        # 檢查是否是 STOMP MESSAGE 幀
        if message.startswith("MESSAGE"):
            # 提取內容部分（body）
            body = message.split("\n\n")[1].strip()  # 獲取 body 部分
            if body.endswith("\x00"):
                body = body[:-1]  # 移除結尾的 \x00
            
            # 解析 JSON
            data = json.loads(body)
            up_data.append(data)
            store_message_in_mongo(body)  # 儲存原始 JSON 訊息
            logger.info("Saved message to MongoDB")
            
            if len(up_data) == 10:
                logger.info(f"Received 10 messages: {up_data}")
        else:
            logger.info(f"Ignoring non-MESSAGE frame: {message}")
    except json.JSONDecodeError as e:
        logger.error(f"Error decoding message body: {e}")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        
def on_error(ws, error):
    """Handle errors encountered during WebSocket communication."""
    logger.error(f"Error: {error}")

def on_close(ws, close_status_code, close_msg):
    """Handle the closing of the WebSocket connection."""
    logger.info("Connection closed")

def on_open(ws):
    """Handle the opening of the WebSocket connection."""
    logger.info("Connection opened")
    
    # 發送 STOMP CONNECT 幀
    connect_msg = "CONNECT\naccept-version:1.2\n\n\x00"
    ws.send(connect_msg)
    logger.info("Sent STOMP CONNECT frame")

    # 發送 STOMP SUBSCRIBE 幀
    subscribe_msg = "SUBSCRIBE\nid:sub-0\ndestination:/topic/metrics\n\n\x00"
    ws.send(subscribe_msg)
    logger.info("Subscribed to /topic/metrics")

def start_websocket():
    ws = websocket.WebSocketApp(WEBSOCKET_URL,
                              on_open=on_open,
                              on_message=on_message,
                              on_error=on_error,
                              on_close=on_close)
    ws.run_forever() 
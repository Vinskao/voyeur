#!/usr/bin/env python3
"""
測試本地 WebSocket 客戶端
"""

import websocket
import json
import time
import logging

# 設置日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def on_message(ws, message):
    """處理接收到的消息"""
    try:
        # 嘗試解析 JSON
        data = json.loads(message)
        logger.info("✅ 成功接收 JSON 數據")
        
        # 顯示關鍵指標
        if 'data' in data:
            metrics = data['data']
            logger.info(f"📊 指標數量: {len(metrics)}")
            
            # 顯示 HTTP 請求統計
            if 'http.server.requests' in metrics:
                requests = metrics['http.server.requests']
                for measurement in requests.get('measurements', []):
                    if measurement.get('statistic') == 'COUNT':
                        logger.info(f"🌐 HTTP 請求數: {measurement.get('value', 0)}")
            
            # 顯示 CPU 使用率
            if 'system.cpu.usage' in metrics:
                cpu = metrics['system.cpu.usage']
                for measurement in cpu.get('measurements', []):
                    if measurement.get('statistic') == 'VALUE':
                        logger.info(f"💻 CPU 使用率: {measurement.get('value', 0):.2%}")
        
        logger.info(f"📝 數據類型: {data.get('type', 'unknown')}")
        logger.info(f"⏰ 時間戳: {data.get('timestamp', 'unknown')}")
        
    except json.JSONDecodeError as e:
        logger.error(f"❌ JSON 解析錯誤: {e}")
        logger.info(f"📄 原始消息: {message[:200]}...")

def on_error(ws, error):
    """處理錯誤"""
    logger.error(f"❌ WebSocket 錯誤: {error}")

def on_close(ws, close_status_code, close_msg):
    """處理連接關閉"""
    logger.info(f"🔌 連接關閉: {close_status_code} - {close_msg}")

def on_open(ws):
    """處理連接開啟"""
    logger.info("🔗 WebSocket 連接已開啟")
    logger.info("📡 等待接收 metrics 數據...")

def main():
    """主函數"""
    websocket_url = "ws://localhost:8080/tymb/metrics"
    
    logger.info(f"🚀 開始連接到: {websocket_url}")
    
    # 創建 WebSocket 連接
    ws = websocket.WebSocketApp(
        websocket_url,
        on_open=on_open,
        on_message=on_message,
        on_error=on_error,
        on_close=on_close
    )
    
    try:
        # 運行 WebSocket 客戶端
        ws.run_forever()
    except KeyboardInterrupt:
        logger.info("⏹️  用戶中斷連接")
    except Exception as e:
        logger.error(f"❌ 連接錯誤: {e}")

if __name__ == "__main__":
    main()

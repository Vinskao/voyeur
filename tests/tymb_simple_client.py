#!/usr/bin/env python3
"""
TYMB 簡化 WebSocket 客戶端
使用正確的 WebSocket URL 連接到 TYMB 服務
"""

import json
import time
import websocket
import stomp
from typing import Optional, Callable


class TYMBSimpleClient:
    def __init__(self, ws_url: str = "wss://peoplesystem.tatdvsonorth.com/tymb/ws/websocket"):
        self.ws_url = ws_url
        self.websocket = None
        self.stomp_client = None
        self.connected = False
        self.metrics_callback: Optional[Callable] = None
        
    def connect(self):
        """連接到 TYMB WebSocket 服務"""
        try:
            print(f"🔍 連接到 TYMB WebSocket: {self.ws_url}")
            
            # 建立 WebSocket 連接
            self.websocket = websocket.create_connection(self.ws_url)
            print("✅ WebSocket 連接成功")
            
            # 建立 STOMP 連接
            self.stomp_client = stomp.Connection()
            self.stomp_client.set_listener('tymb', TYMBListener(self))
            
            # 連接到 STOMP
            self.stomp_client.connect(
                host="peoplesystem.tatdvsonorth.com",
                port=80,
                wait=True
            )
            
            self.connected = True
            print("✅ STOMP 連接成功")
            
            # 訂閱 metrics topic
            self.stomp_client.subscribe('/topic/metrics', id=1, ack='auto')
            print("✅ 已訂閱 /topic/metrics")
            
            return True
            
        except Exception as e:
            print(f"❌ 連接失敗: {e}")
            return False
    
    def disconnect(self):
        """斷開連接"""
        if self.stomp_client and self.connected:
            self.stomp_client.disconnect()
            self.connected = False
        
        if self.websocket:
            self.websocket.close()
        
        print("🔌 已斷開連接")
    
    def request_metrics(self):
        """請求 metrics 數據"""
        if not self.connected:
            print("❌ 未連接，請先調用 connect()")
            return
        
        try:
            # 發送 STOMP 消息
            self.stomp_client.send("/app/", json.dumps("get-metrics"))
            print("📤 已發送 metrics 請求")
        except Exception as e:
            print(f"❌ 發送請求失敗: {e}")
    
    def send_message(self, destination: str, message: str):
        """發送消息到指定目的地"""
        if not self.connected:
            print("❌ 未連接，請先調用 connect()")
            return
        
        try:
            self.stomp_client.send(destination, message)
            print(f"📤 已發送消息到 {destination}: {message}")
        except Exception as e:
            print(f"❌ 發送消息失敗: {e}")
    
    def set_metrics_callback(self, callback: Callable):
        """設置 metrics 回調函數"""
        self.metrics_callback = callback


class TYMBListener(stomp.ConnectionListener):
    def __init__(self, client: TYMBSimpleClient):
        self.client = client
    
    def on_connected(self, frame):
        print(f"🎉 STOMP 連接成功: {frame}")
    
    def on_message(self, frame):
        print(f"📨 收到 STOMP 消息:")
        print(f"   目的地: {frame.headers.get('destination', 'N/A')}")
        print(f"   內容: {frame.body}")
        
        try:
            # 嘗試解析 JSON
            data = json.loads(frame.body)
            print(f"📊 解析後的數據: {json.dumps(data, indent=2, ensure_ascii=False)}")
            
            # 如果是 metrics 消息，調用回調
            destination = frame.headers.get('destination', '')
            if destination == '/topic/metrics' and self.client.metrics_callback:
                self.client.metrics_callback(data)
                
        except json.JSONDecodeError:
            print(f"📝 原始數據: {frame.body}")
    
    def on_error(self, frame):
        print(f"❌ STOMP 錯誤: {frame}")
    
    def on_disconnected(self):
        print("🔌 STOMP 連接斷開")


def test_tymb_simple():
    """測試 TYMB 簡化客戶端"""
    client = TYMBSimpleClient()
    
    def on_metrics(data):
        print(f"🎯 回調收到 metrics: {type(data)}")
        print(f"📊 Metrics 數據: {json.dumps(data, indent=2, ensure_ascii=False)}")
    
    client.set_metrics_callback(on_metrics)
    
    if client.connect():
        print("\n🎯 開始測試...")
        
        # 請求 metrics
        client.request_metrics()
        
        # 發送測試消息
        client.send_message("/app/test", json.dumps({"type": "ping", "timestamp": time.time()}))
        
        # 保持連接一段時間
        print("⏳ 等待 15 秒接收數據...")
        time.sleep(15)
        
        client.disconnect()
    else:
        print("❌ 連接失敗")


if __name__ == "__main__":
    test_tymb_simple()

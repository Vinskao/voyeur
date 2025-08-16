#!/usr/bin/env python3
"""
測試 WebSocket 配置
"""

import os
from dotenv import load_dotenv

# 載入環境變數
load_dotenv()

def test_websocket_config():
    """測試 WebSocket 配置"""
    print("🔍 測試 WebSocket 配置")
    print("=" * 50)
    
    # 測試環境變數
    websocket_tymb = os.getenv('WEBSOCKET_TYMB', 'Not set')
    print(f"🌍 環境變數 WEBSOCKET_TYMB: {websocket_tymb}")
    
    # 測試 metrics 配置
    try:
        from metrics.config import WEBSOCKET_TYMB
        print(f"📈 Metrics WEBSOCKET_TYMB: {WEBSOCKET_TYMB}")
        
        # 驗證 URL 格式
        if WEBSOCKET_TYMB == "ws://localhost:8080/tymb/metrics":
            print("✅ WebSocket URL 格式正確 (本地端點)")
        else:
            print("❌ WebSocket URL 格式不正確")
            
    except ImportError as e:
        print(f"❌ 無法導入 metrics 配置: {e}")
    
    print("\n📊 預期的數據格式:")
    print("- 端點: ws://localhost:8080/tymb/metrics")
    print("- 格式: JSON (Spring Boot Actuator metrics)")
    print("- 包含: http.server.requests, system.cpu.usage, jvm.memory.used 等")
    
    print("\n✅ 配置測試完成")

if __name__ == "__main__":
    test_websocket_config()

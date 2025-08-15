#!/usr/bin/env python3
"""
測試新的 WebSocket 配置
"""

import os
import sys
import django
from django.conf import settings

# 設置 Django 環境
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'voyeur.settings')
django.setup()

def test_websocket_config():
    """測試 WebSocket 配置"""
    print("🔍 測試 WebSocket 配置")
    print("=" * 50)
    
    # 測試 Django settings
    print(f"📊 Django WEBSOCKET_TYMB: {settings.WEBSOCKET_TYMB}")
    print(f"📊 Django WEBSOCKET_URL: {settings.WEBSOCKET_URL}")
    
    # 測試環境變數
    print(f"🌍 環境變數 WEBSOCKET_TYMB: {os.getenv('WEBSOCKET_TYMB', 'Not set')}")
    
    # 測試 metrics 配置
    try:
        from metrics.config import WEBSOCKET_TYMB, WEBSOCKET_URL
        print(f"📈 Metrics WEBSOCKET_TYMB: {WEBSOCKET_TYMB}")
        print(f"📈 Metrics WEBSOCKET_URL: {WEBSOCKET_URL}")
    except ImportError as e:
        print(f"❌ 無法導入 metrics 配置: {e}")
    
    print("\n✅ 配置測試完成")

if __name__ == "__main__":
    test_websocket_config()

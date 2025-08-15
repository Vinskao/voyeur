#!/bin/bash

echo "🚀 測試新的 WebSocket 連接"
echo "=========================="

WEBSOCKET_URL="ws://peoplesystem.tatdvsonorth.com/tymb/ws/websocket"

echo "1. 測試 WebSocket 握手..."
curl -s -w "HTTP Status: %{http_code}\n" \
  -H "Upgrade: websocket" \
  -H "Connection: Upgrade" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  -H "Sec-WebSocket-Version: 13" \
  "$WEBSOCKET_URL"

echo -e "\n2. 測試 STOMP 連接..."
echo "WebSocket URL: $WEBSOCKET_URL"

echo -e "\n3. 使用 wscat 測試 (如果可用)..."
if command -v wscat &> /dev/null; then
    echo "嘗試 WebSocket 連接..."
    timeout 10 wscat -c "$WEBSOCKET_URL" || echo "WebSocket 連接失敗"
else
    echo "wscat 未安裝，跳過 WebSocket 測試"
    echo "你可以安裝 wscat: npm install -g wscat"
fi

echo -e "\n4. 測試 HTTP 連接..."
curl -s -w "HTTP Status: %{http_code}\n" \
  "http://peoplesystem.tatdvsonorth.com/tymb/ws"

echo -e "\n✅ 測試完成"

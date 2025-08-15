#!/bin/bash

echo "🚀 測試 WebSocket 連接"
echo "======================"

WEBSOCKET_URL="ws://peoplesystem.tatdvsonorth.com/tymb/ws/websocket"

echo "1. 測試 WebSocket 握手..."
curl -s -w "HTTP Status: %{http_code}\n" \
  -H "Upgrade: websocket" \
  -H "Connection: Upgrade" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  -H "Sec-WebSocket-Version: 13" \
  "$WEBSOCKET_URL"

echo -e "\n2. 測試 HTTP 連接..."
curl -s -w "HTTP Status: %{http_code}\n" \
  "http://peoplesystem.tatdvsonorth.com/tymb/ws"

echo -e "\n3. 測試 HTTPS 連接..."
curl -s -w "HTTP Status: %{http_code}\n" \
  "https://peoplesystem.tatdvsonorth.com/tymb/ws"

echo -e "\n✅ 測試完成"

#!/bin/bash

echo "🚀 測試本地 WebSocket 連接"
echo "=========================="

WEBSOCKET_URL="ws://localhost:8080/tymb/metrics"

echo "1. 測試 WebSocket 握手..."
curl -s -w "HTTP Status: %{http_code}\n" \
  -H "Upgrade: websocket" \
  -H "Connection: Upgrade" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  -H "Sec-WebSocket-Version: 13" \
  "$WEBSOCKET_URL"

echo -e "\n2. 測試 HTTP 連接..."
curl -s -w "HTTP Status: %{http_code}\n" \
  "http://localhost:8080/tymb/metrics"

echo -e "\n3. 測試 Actuator 端點..."
curl -s -w "HTTP Status: %{http_code}\n" \
  "http://localhost:8080/actuator/metrics"

echo -e "\n4. 測試健康檢查..."
curl -s -w "HTTP Status: %{http_code}\n" \
  "http://localhost:8080/actuator/health"

echo -e "\n✅ 測試完成"

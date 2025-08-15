#!/bin/bash

echo "🚀 測試 TYMB 服務連接"
echo "===================="

BASE_URL="https://peoplesystem.tatdvsonorth.com"

echo "1. 測試基本連接..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "$BASE_URL"

echo -e "\n2. 測試 TYMB WebSocket 端點..."
curl -s -w "HTTP Status: %{http_code}\n" "$BASE_URL/tymb/ws"

echo -e "\n3. 測試 TYMB 根路徑..."
curl -s -w "HTTP Status: %{http_code}\n" "$BASE_URL/tymb/"

echo -e "\n4. 測試 WebSocket 升級請求..."
curl -s -w "HTTP Status: %{http_code}\n" \
  -H "Upgrade: websocket" \
  -H "Connection: Upgrade" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  -H "Sec-WebSocket-Version: 13" \
  "$BASE_URL/tymb/ws"

echo -e "\n5. 測試 SockJS 資訊端點..."
curl -s -w "HTTP Status: %{http_code}\n" "$BASE_URL/tymb/ws/info"

echo -e "\n6. 測試 SockJS 伺服器資訊..."
curl -s -w "HTTP Status: %{http_code}\n" "$BASE_URL/tymb/ws/server"

echo -e "\n7. 測試 CORS 預檢請求..."
curl -s -w "HTTP Status: %{http_code}\n" \
  -H "Origin: https://peoplesystem.tatdvsonorth.com" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: X-Requested-With" \
  -X OPTIONS \
  "$BASE_URL/tymb/ws"

echo -e "\n8. 測試完整的 SockJS 連接流程..."
echo "獲取 SockJS 伺服器資訊..."
SERVER_INFO=$(curl -s "$BASE_URL/tymb/ws/info")
echo "伺服器資訊: $SERVER_INFO"

echo -e "\n9. 測試 WebSocket 連接 (使用 wscat 如果可用)..."
if command -v wscat &> /dev/null; then
    echo "嘗試 WebSocket 連接..."
    timeout 5 wscat -c "wss://peoplesystem.tatdvsonorth.com/tymb/ws" || echo "WebSocket 連接失敗"
else
    echo "wscat 未安裝，跳過 WebSocket 測試"
fi

echo -e "\n✅ 測試完成"

from channels.generic.websocket import AsyncWebsocketConsumer  # 從 Channels 框架導入 WebSocket 非同步消費者基底類別
import json  # 導入 JSON 模組，用於資料的編碼與解碼

class AdminMetricsConsumer(AsyncWebsocketConsumer):
    """
    後台管理 WebSocket 消費者類別
    用於處理後台管理的測量資料或通知
    """
    async def connect(self):
        """
        當有 WebSocket 連線請求時，此方法會被呼叫
        在此方法中接受連線以建立通訊
        """
        await self.accept()  # 接受來自客戶端的連線請求
        # TODO: 在此處添加對後台管理 metrics 的進一步處理

    async def disconnect(self, close_code):
        """
        當 WebSocket 連線關閉時，此方法會被呼叫
        close_code 參數表示關閉連線時的狀態碼
        """
        # 可在此釋放資源或進行後續的清理工作
        pass

    async def receive(self, text_data=None):
        """
        當 WebSocket 收到訊息時，此方法會被呼叫
        text_data 參數通常為 JSON 格式的文字資料
        """
        # 範例：回傳一則確認訊息告知已收到後台管理的 metrics
        response_data = {
            "message": "Admin metrics received"  # 回應訊息內容
        }
        await self.send(text_data=json.dumps(response_data))  # 將字典轉換為 JSON 格式後傳送給客戶端

class PublicMetricsConsumer(AsyncWebsocketConsumer):
    """
    公共端 WebSocket 消費者類別
    用於處理公開訪問的測量資料或通知
    """
    async def connect(self):
        """
        當有 WebSocket 連線請求時，接受連線以建立通訊
        """
        await self.accept()  # 接受連線請求
        # TODO: 在此處添加對公共端 metrics 的進一步處理

    async def disconnect(self, close_code):
        """
        當 WebSocket 連線關閉時調用
        close_code 用來表示關閉的狀態碼
        """
        # 此處可以增加清理資源或其他連線終止後的處理
        pass

    async def receive(self, text_data=None):
        """
        當 WebSocket 收到訊息時，此方法會被呼叫
        text_data 為傳入的文字資料（通常為 JSON 格式）
        """
        # 範例：回傳一則確認訊息告知已收到公共端的 metrics
        response_data = {
            "message": "Public metrics received"  # 回應訊息內容
        }
        await self.send(text_data=json.dumps(response_data))  # 將回應字典轉成 JSON 字串後，發送回用戶端 
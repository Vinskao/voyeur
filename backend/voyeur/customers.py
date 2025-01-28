from channels.generic.websocket import AsyncWebsocketConsumer
import json

class MetricsConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.accept()
        # 可以在這裡添加更多的連接邏輯

    async def disconnect(self, close_code):
        # 可以在這裡添加更多的斷開連接邏輯
        pass

    async def receive(self, text_data):
        # 處理接收到的消息
        data = json.loads(text_data)
        # 回應消息
        await self.send(text_data=json.dumps({
            'message': 'Message received'
        }))
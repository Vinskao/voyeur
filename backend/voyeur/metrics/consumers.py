import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from .store import store_message_in_mongo

logger = logging.getLogger(__name__)

class MetricsConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.accept()
        logger.info("WebSocket connection established")

    async def disconnect(self, close_code):
        logger.info(f"WebSocket connection closed with code: {close_code}")

    async def receive(self, text_data):
        try:
            # 解析 JSON 訊息
            data = json.loads(text_data)
            
            # 儲存到 MongoDB
            await store_message_in_mongo(text_data)
            logger.info("Message stored in MongoDB successfully")
            
            # 發送確認訊息
            await self.send(text_data=json.dumps({
                'status': 'success',
                'message': 'Data received and stored'
            }))
            
        except json.JSONDecodeError as e:
            logger.error(f"Error decoding message: {e}")
            await self.send(text_data=json.dumps({
                'status': 'error',
                'message': 'Invalid JSON format'
            }))
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            await self.send(text_data=json.dumps({
                'status': 'error',
                'message': 'Internal server error'
            })) 
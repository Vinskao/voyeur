import pymongo
import logging
import json
from datetime import datetime
from voyeur.core.config import MONGODB_URI, MONGODB_DB, MONGODB_COLLECTION

# 設置日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def store_message_in_mongo(message):
    """Store the message in MongoDB."""
    try:
        # 連接到 MongoDB
        client = pymongo.MongoClient(MONGODB_URI)
        db = client[MONGODB_DB]
        collection = db[MONGODB_COLLECTION]

        # 解析 JSON 訊息
        data = json.loads(message)
        
        # 添加時間戳
        data['timestamp'] = datetime.utcnow()
        
        # 儲存到 MongoDB
        collection.insert_one(data)
        logger.info("Message stored in MongoDB successfully")
        
    except Exception as e:
        logger.error(f"Error storing message in MongoDB: {e}")
        raise
    finally:
        client.close() 
import pymongo
import json
import logging
from datetime import datetime
from dotenv import load_dotenv
import os

# 加載 .env 文件中的環境變量
load_dotenv()

# 設置日誌
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# MongoDB 連接設置
mongo_uri = os.getenv("MONGO_URI")
client = pymongo.MongoClient(mongo_uri)
db = client['voyeur']
collection = db['ty_backend_metrics']

def store_message_in_mongo(message):
    """將接收到的訊息存入 MongoDB。"""
    # logger.info("開始處理訊息")
    try:
        # 將 JSON 字符串轉換為字典
        # logger.info("嘗試將訊息轉換為字典")
        data = json.loads(message)
        # logger.info(f"成功轉換訊息: {data}")
        
        # 添加 createdAt 字段
        data['createdAt'] = datetime.utcnow()
        
        # 插入數據到 MongoDB
        # logger.info("嘗試將數據插入 MongoDB")
        collection.insert_one(data)
        logger.info("成功將訊息存入 MongoDB")
    except json.JSONDecodeError as e:
        logger.error(f"JSON 解碼錯誤: {e}")
    except pymongo.errors.PyMongoError as e:
        logger.error(f"MongoDB 錯誤: {e}")
    finally:
        logger.info("處理訊息結束")

# 創建 TTL 索引
collection.create_index("createdAt", expireAfterSeconds=86400)
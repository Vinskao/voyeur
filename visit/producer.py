"""Redis producer module for pushing messages to a queue."""

import redis
import sys
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Redis 設定
REDIS_HOST = os.getenv('REDIS_HOST')
REDIS_PORT = int(os.getenv('REDIS_CUSTOM_PORT'))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')
QUEUE_NAME = os.getenv('REDIS_QUEUE_NAME')

app = FastAPI()

class PushRequest(BaseModel):
    value: int = 1

def get_redis_connection():
    try:
        r = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_PASSWORD,
            decode_responses=True
        )
        r.ping()  # 測試連線
        return r
    except redis.exceptions.ConnectionError as e:
        raise HTTPException(status_code=500, detail=f"Redis connection error: {str(e)}")

@app.post("/voyeur/push")
async def push_to_queue(request: PushRequest):
    r = get_redis_connection()
    r.rpush(QUEUE_NAME, request.value)
    length = r.llen(QUEUE_NAME)
    return {
        "status": "success",
        "message": f"Pushed {request.value} to queue",
        "queue_length": length
    }

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

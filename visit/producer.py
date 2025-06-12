"""Redis producer module for pushing messages to a queue."""

import redis
import sys
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Redis 設定
REDIS_HOST = '138.2.46.52'
REDIS_PORT = 30678
REDIS_PASSWORD = 'RedisPassword123'
QUEUE_NAME = 'increment_queue'

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

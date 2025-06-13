import os
import redis
import requests

# Redis 設定（透過環境變數）
REDIS_HOST = os.getenv("REDIS_HOST")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")
QUEUE_NAME = os.getenv("REDIS_QUEUE_NAME")

# API 設定
API_URL = os.getenv("API_URL")

r = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=REDIS_PASSWORD,
    decode_responses=True
)

print("Consumer started and listening...")

while True:
    try:
        item = r.blpop(QUEUE_NAME, timeout=5)
        if item:
            print("Popped from queue, calling API...")
            res = requests.post(API_URL, timeout=5)
            print(f"API responded: {res.status_code}")
    except Exception as e:
        print(f"Error: {e}")

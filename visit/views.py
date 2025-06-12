from django.http import JsonResponse
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
import redis
import os

# Redis 設定
REDIS_HOST = os.getenv('REDIS_HOST', '138.2.46.52')
REDIS_PORT = int(os.getenv('REDIS_PORT', 30678))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', 'RedisPassword123')
QUEUE_NAME = os.getenv('REDIS_QUEUE_NAME', 'increment_queue')

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
        raise Exception(f"Redis connection error: {str(e)}")

class VisitCountView(View):
    def get(self, request):
        r = get_redis_connection()
        count = r.get('visit_count') or 0
        return JsonResponse({'count': int(count)})

class IncrementView(View):
    def post(self, request):
        r = get_redis_connection()
        r.incr('visit_count')
        count = r.get('visit_count')
        return JsonResponse({'count': int(count)})

@method_decorator(csrf_exempt, name='dispatch')
class PushView(View):
    def post(self, request):
        try:
            value = int(request.POST.get('value', 1))
            r = get_redis_connection()
            r.rpush(QUEUE_NAME, value)
            length = r.llen(QUEUE_NAME)
            return JsonResponse({
                "status": "success",
                "message": f"Pushed {value} to queue",
                "queue_length": length
            })
        except Exception as e:
            return JsonResponse({
                "status": "error",
                "message": str(e)
            }, status=500) 
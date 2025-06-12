from django.http import JsonResponse
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
import redis
import os
from urllib.parse import urlparse
import logging

logger = logging.getLogger(__name__)

def parse_redis_url(url):
    """Parse Redis URL into host and port."""
    if not url:
        raise ValueError("REDIS_HOST environment variable is required")
    
    if url.startswith('tcp://'):
        parsed = urlparse(url)
        host = parsed.hostname
        port = parsed.port or 6379
        return host, port
    return url, int(os.getenv('REDIS_CUSTOM_PORT', '6379'))

# Redis 設定
REDIS_HOST, REDIS_PORT = parse_redis_url(os.getenv('REDIS_HOST'))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')
REDIS_QUEUE_NAME = os.getenv('REDIS_QUEUE_NAME')

if not all([REDIS_HOST, REDIS_PASSWORD, REDIS_QUEUE_NAME]):
    raise ValueError("Missing required Redis environment variables")

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
        logger.error(f"Redis connection error: {str(e)}")
        raise Exception(f"Redis connection error: {str(e)}")

class VisitCountView(View):
    def get(self, request):
        try:
            r = get_redis_connection()
            count = r.get('visit_count')
            logger.info(f"Current visit count: {count}")
            if count is None:
                count = 0
            return JsonResponse({'count': int(count)})
        except Exception as e:
            logger.error(f"Error getting visit count: {str(e)}")
            return JsonResponse({'error': str(e)}, status=500)

@method_decorator(csrf_exempt, name='dispatch')
class IncrementView(View):
    def post(self, request):
        try:
            r = get_redis_connection()
            count = r.incr('visit_count')
            logger.info(f"Incremented visit count to: {count}")
            return JsonResponse({'count': int(count)})
        except Exception as e:
            logger.error(f"Error incrementing visit count: {str(e)}")
            return JsonResponse({'error': str(e)}, status=500)

@method_decorator(csrf_exempt, name='dispatch')
class PushView(View):
    def post(self, request):
        try:
            value = int(request.POST.get('value', 1))
            r = get_redis_connection()
            r.rpush(REDIS_QUEUE_NAME, value)
            length = r.llen(REDIS_QUEUE_NAME)
            logger.info(f"Pushed {value} to queue, current length: {length}")
            return JsonResponse({
                "status": "success",
                "message": f"Pushed {value} to queue",
                "queue_length": length
            })
        except Exception as e:
            logger.error(f"Error pushing to queue: {str(e)}")
            return JsonResponse({
                "status": "error",
                "message": str(e)
            }, status=500) 
from django.http import JsonResponse

def metrics_view(request):
    # 你可以在這裡寫入收集 metrics 的邏輯
    return JsonResponse({"status": "ok"})
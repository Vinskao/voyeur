from django.http import JsonResponse

def metrics_view(request):
    """
    A simple view that returns a JSON response.
    """
    data = {"message": "Hello, this is the metrics view."}
    return JsonResponse(data) 
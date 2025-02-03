from rest_framework.decorators import api_view
from rest_framework.response import Response
import logging
from voyeur.orm_metrics import MongoORM

logger = logging.getLogger(__name__)

@api_view(['GET'])
def hello(request):
    name = request.GET.get('name', 'guest')
    data = {
        'name': name,
        'message': f"Hello {name}, your first API endpoint has been created successfully!"
    }
    return Response(data)

@api_view(['GET'])
def metrics(request):
    """
    取得最新100筆文件，並回傳 JSON 格式的結果
    """
    try:
        database_name = 'voyeur'
        collection_name = 'ty_backend_metrics'
        orm = MongoORM(database_name, collection_name)
        documents = orm.select_all()  # 取得文件列表

        # ObjectId 無法直接序列化，轉換成 str
        for doc in documents:
            if '_id' in doc:
                doc['_id'] = str(doc['_id'])
        return Response(documents)
    except Exception as e:
        logger.error("Error fetching metrics: %s", e)
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def server_info(request):
    """
    回傳簡單的 server info 資訊
    """
    host = request.get_host()
    return Response({'server_info': f"Server is running on: {host}"}) 
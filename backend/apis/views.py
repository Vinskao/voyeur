from rest_framework.decorators import api_view
from django.http import JsonResponse, HttpResponse
import datetime
import logging
import platform
from voyeur.orm_metrics import MongoORM  # Ensure MongoORM is defined in voyeur/orm_metrics.py

logger = logging.getLogger(__name__)

@api_view(['GET'])
def hello(request):
    """
    Return a simple "Hello, World!" message.
    """
    return HttpResponse("Hello, World!")

@api_view(['GET'])
def metrics(request):
    """
    Return some basic system metrics.
    """
    data = {
        "timestamp": datetime.datetime.now().isoformat(),
        "platform": platform.system(),
        "release": platform.release(),
    }
    return JsonResponse(data)

@api_view(['GET'])
def server_info(request):
    """
    Return server information.
    """
    data = {
        "python_version": platform.python_version(),
        "os": platform.platform(),
        "processor": platform.processor(),
        "time": datetime.datetime.now().isoformat(),
    }
    return JsonResponse(data)

@api_view(['GET'])
def orm_metrics_view(request):
    """
    HTTP GET endpoint for retrieving ORM metrics from the 'ty_backend_metrics' collection.
    """
    database_name = 'voyeur'
    collection_name = 'ty_backend_metrics'
    orm = MongoORM(database_name, collection_name)
    documents = orm.select_all()

    # Convert ObjectId to string for JSON serialization
    for doc in documents:
        if '_id' in doc:
            doc['_id'] = str(doc['_id'])

    return JsonResponse({
        'documents': documents,
        'timestamp': datetime.datetime.now().isoformat()
    })

@api_view(['DELETE'])
def delete_all_documents(request):
    """
    HTTP DELETE endpoint for deleting all documents in the 'ty_backend_metrics' collection.
    """
    database_name = 'voyeur'
    collection_name = 'ty_backend_metrics'
    orm = MongoORM(database_name, collection_name)
    
    # Using an empty filter {} deletes all documents in the collection.
    delete_result = orm.delete({})
    
    return JsonResponse({
        'deleted_count': delete_result.deleted_count,
        'timestamp': datetime.datetime.now().isoformat()
    })
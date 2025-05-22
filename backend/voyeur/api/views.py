from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import pymongo
from voyeur.core.config import MONGODB_URI, MONGODB_DB, MONGODB_COLLECTION

class MongoORM:
    def __init__(self, database_name, collection_name, uri=MONGODB_URI):
        self.client = pymongo.MongoClient(uri)
        self.database = self.client[database_name]
        self.collection = self.database[collection_name]

    def select_all(self):
        """Fetch all documents from the collection."""
        return list(self.collection.find())

@csrf_exempt
def get_metrics(request):
    """API endpoint to get all metrics."""
    if request.method == 'GET':
        orm = MongoORM(MONGODB_DB, MONGODB_COLLECTION)
        docs = orm.select_all()

        # Convert ObjectId to string for JSON serialization
        for doc in docs:
            if '_id' in doc:
                doc['_id'] = str(doc['_id'])
        return JsonResponse(docs, safe=False)
    
    return JsonResponse({'error': 'Method not allowed'}, status=405) 
import os
import time
import pymongo
import logging
from dotenv import load_dotenv

# Load environment variables from .env file (includes sensitive data like MONGO_URI)
load_dotenv()

# Retrieve MongoDB URI from environment variables
mongo_uri = os.getenv("MONGO_URI")
if not mongo_uri:
    raise ValueError("MONGO_URI is not set in the environment variables.")

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Import Django HTTP utilities
from django.http import JsonResponse
from django.views.decorators.http import require_GET

class MongoORM:
    """
    A simple ORM for interacting with MongoDB.
    This class provides basic CRUD operations for a given database and collection.
    """
    def __init__(self, database_name, collection_name):
        """
        Initialize the MongoORM instance by connecting to the specified database and collection.
        
        Parameters:
            database_name (str): Name of the MongoDB database.
            collection_name (str): Name of the collection (similar to a table in SQL).
        """
        self.client = pymongo.MongoClient(mongo_uri)
        self.db = self.client[database_name]
        self.collection = self.db[collection_name]
        logger.info(f"已連線到 MongoDB：資料庫='{database_name}', 集合='{collection_name}'")

    def select_all(self, query_filter=None):
        """
        Query and return the latest 100 documents from the collection (sorted by ObjectId in descending order).

        Parameters:
            query_filter (dict, optional): Filter condition for the query. Defaults to an empty dict.
        
        Returns:
            list: A list of the latest 100 documents.
        """
        logger.info("執行查詢最新100個文件 (select_all) 操作。")
        if query_filter is None:
            query_filter = {}
        documents = list(
            self.collection.find(query_filter)
            .sort("_id", pymongo.DESCENDING)
            .limit(100)
        )
        return documents

    def insert(self, data):
        """
        Insert a new document into the collection.
        
        Parameters:
            data (dict): The document data to insert.
        
        Returns:
            InsertOneResult: Result of the insertion operation (contains the new document's ID, etc.).
        """
        logger.info("執行插入操作 (insert)。")
        return self.collection.insert_one(data)

    def update(self, query_filter, update_values):
        """
        Update documents in the collection that match the query_filter.
        
        Parameters:
            query_filter (dict): The filter condition to match documents.
            update_values (dict): The fields and values to update.
        
        Returns:
            UpdateResult: Result of the update operation (contains the number of documents updated, etc.).
        """
        logger.info("執行更新操作 (update)。")
        return self.collection.update_many(query_filter, {"$set": update_values})

    def delete(self, query_filter):
        """
        Delete documents from the collection that match the query_filter.
        
        Parameters:
            query_filter (dict): The filter condition to select documents for deletion.
        
        Returns:
            DeleteResult: Result of the delete operation (contains the number of documents deleted, etc.).
        """
        logger.info("執行刪除操作 (delete)。")
        return self.collection.delete_many(query_filter)

@require_GET
def get_orm_metrics_view(request):
    _ = request  # Explicitly mark the request as used (unused in the function)
    """
    HTTP GET endpoint that queries the 'ty_backend_metrics' collection
    and returns the latest 100 documents as a JSON response.
    """
    logger.info("收到 GET 請求，開始查詢最新 100 個文件。")
    database_name = 'voyeur'
    collection_name = 'ty_backend_metrics'
    orm = MongoORM(database_name, collection_name)
    documents = orm.select_all()

    # Convert any special types (e.g., ObjectId) to a JSON-serializable format.
    for doc in documents:
        if "_id" in doc:
            doc["_id"] = str(doc["_id"])

    return JsonResponse({"documents": documents})

# def run_orm_metrics():
#     """
#     Periodically query the database every 30 seconds and log the latest 100 documents.
#     This function demonstrates how you might run continuous database metrics logging.
#     """
#     database_name = 'voyeur'
#     collection_name = 'ty_backend_metrics'
#     orm = MongoORM(database_name, collection_name)
#     while True:
#         documents = orm.select_all()
#         logger.info("所有文件:")
#         for doc in documents:
#             logger.info(doc)
#         time.sleep(30)
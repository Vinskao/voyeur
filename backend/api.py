from flask import Flask, jsonify
import pymongo
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# MongoORM: A simple ORM for interacting with MongoDB
# ---------------------------------------------------------------------------
class MongoORM:
    def __init__(self, database_name, collection_name, uri="mongodb://localhost:27017/"):
        self.client = pymongo.MongoClient(uri)
        self.database = self.client[database_name]
        self.collection = self.database[collection_name]

    def select_all(self):
        """Fetch all documents from the collection."""
        return list(self.collection.find())

# ---------------------------------------------------------------------------
# Flask API for serving metrics from MongoDB
# ---------------------------------------------------------------------------
app = Flask(__name__)

@app.route('/metrics', methods=['GET'])
def get_metrics():
    # Set your desired database and collection names
    database_name = "voyeur"
    collection_name = "ty_backend_metrics"
    
    orm = MongoORM(database_name, collection_name)
    docs = orm.select_all()

    # Convert ObjectId to string for JSON serialization
    for doc in docs:
        if '_id' in doc:
            doc['_id'] = str(doc['_id'])
    return jsonify(docs)

if __name__ == '__main__':
    app.run(debug=True) 
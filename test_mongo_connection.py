from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# MongoDB settings
MONGODB_PASSWORD = os.getenv('MONGODB_PASSWORD', 'Wawi247525')
MONGODB_DB = os.getenv('MONGODB_DB', 'voyeur')
MONGODB_COLLECTION = os.getenv('MONGODB_COLLECTION', 'metrics')

# MongoDB connection string
uri = f"mongodb+srv://tianyikao:{MONGODB_PASSWORD}@palais.7t2na.mongodb.net/?retryWrites=true&w=majority&appName=palais"

try:
    # Create a new client and connect to the server
    client = MongoClient(uri, server_api=ServerApi('1'))
    
    # Send a ping to confirm a successful connection
    client.admin.command('ping')
    print("Pinged your deployment. You successfully connected to MongoDB!")
    
    # Get the database and collection
    db = client[MONGODB_DB]
    collection = db[MONGODB_COLLECTION]

    # Test connection by listing all documents in the collection
    documents = list(collection.find({}, {'_id': 0}))
    print("\nDocuments in collection:")
    for doc in documents:
        print(doc)

except Exception as e:
    print(f"Error connecting to MongoDB: {e}")
finally:
    client.close() 
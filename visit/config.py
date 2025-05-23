import os
from dotenv import load_dotenv

load_dotenv()

def get_mongo_config():
    return {
        'connection_string': os.getenv('MONGODB_URI', 'mongodb://localhost:27017'),
        'username': os.getenv('MONGODB_USERNAME'),
        'password': os.getenv('MONGODB_PASSWORD'),
        'auth_source': os.getenv('MONGODB_AUTH_SOURCE', 'admin'),
    } 
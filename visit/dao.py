from pymongo import MongoClient
from datetime import datetime
from .config import get_mongo_config

class VisitCountDAO:
    def __init__(self):
        config = get_mongo_config()
        self.client = MongoClient(
            config['connection_string'],
            username=config['username'],
            password=config['password'],
            authSource=config['auth_source'],
            tls=True,
            tlsAllowInvalidCertificates=True
        )
        self.db = self.client['voyeur']
        self.collection = self.db['tyf_visits']

    def get_count(self):
        """Get the current visit count"""
        counter = self.collection.find_one({'_id': 'visit_counter'})
        if not counter:
            # Initialize counter if it doesn't exist
            now = datetime.utcnow().isoformat() + 'Z'
            counter = {
                '_id': 'visit_counter',
                'count': 0,
                'last_updated': now
            }
            self.collection.insert_one(counter)
        return counter['count']

    def increment_count(self):
        """Increment the visit count and return the new value"""
        now = datetime.utcnow().isoformat() + 'Z'
        result = self.collection.find_one_and_update(
            {'_id': 'visit_counter'},
            {
                '$inc': {'count': 1},
                '$set': {'last_updated': now}
            },
            upsert=True,
            return_document=True
        )
        return result['count']

    def __del__(self):
        """Close MongoDB connection when object is destroyed"""
        if hasattr(self, 'client'):
            self.client.close() 
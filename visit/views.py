from django.http import JsonResponse
from pymongo import MongoClient
from datetime import datetime
import os
from .config import get_mongo_config
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from rest_framework.decorators import api_view

def get_mongo_client():
    config = get_mongo_config()
    client = MongoClient(
        config['connection_string'],
        username=config['username'],
        password=config['password'],
        authSource=config['auth_source'],
        tls=True,
        tlsAllowInvalidCertificates=True
    )
    return client

@swagger_auto_schema(
    method='get',
    operation_description="Get the current visit count",
    responses={
        200: openapi.Response(
            description="Success",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={
                    'count': openapi.Schema(type=openapi.TYPE_INTEGER),
                    'last_updated': openapi.Schema(type=openapi.TYPE_STRING, format='date-time'),
                }
            )
        ),
        500: openapi.Response(description="Server Error")
    }
)
@api_view(['GET'])
def get_visit_count(request):
    client = None
    try:
        client = get_mongo_client()
        db = client['voyeur']
        collection = db['tyf_visits']
        
        counter = collection.find_one({'_id': 'visit_counter'})
        if not counter:
            # Initialize counter if it doesn't exist
            now = datetime.utcnow().isoformat() + 'Z'
            counter = {
                '_id': 'visit_counter',
                'count': 0,
                'last_updated': now
            }
            collection.insert_one(counter)
        
        return JsonResponse({
            'count': counter['count'],
            'last_updated': counter['last_updated']
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
    finally:
        if client:
            client.close()

@swagger_auto_schema(
    method='get',
    operation_description="Increment the visit count",
    responses={
        200: openapi.Response(
            description="Success",
            schema=openapi.Schema(
                type=openapi.TYPE_OBJECT,
                properties={
                    'count': openapi.Schema(type=openapi.TYPE_INTEGER),
                    'last_updated': openapi.Schema(type=openapi.TYPE_STRING, format='date-time'),
                }
            )
        ),
        500: openapi.Response(description="Server Error")
    }
)
@api_view(['GET'])
def increment_visit_count(request):
    client = None
    try:
        client = get_mongo_client()
        db = client['voyeur']
        collection = db['tyf_visits']
        
        now = datetime.utcnow().isoformat() + 'Z'
        result = collection.find_one_and_update(
            {'_id': 'visit_counter'},
            {
                '$inc': {'count': 1},
                '$set': {'last_updated': now}
            },
            upsert=True,
            return_document=True
        )
        
        return JsonResponse({
            'count': result['count'],
            'last_updated': result['last_updated']
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)
    finally:
        if client:
            client.close() 
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .dao import VisitCountDAO
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from rest_framework.views import APIView
from rest_framework.response import Response

class VisitCountView(APIView):
    @swagger_auto_schema(
        operation_description="Get current visit count",
        responses={
            200: openapi.Response(
                description="Success",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={
                        'count': openapi.Schema(type=openapi.TYPE_INTEGER, description='Current visit count'),
                    }
                )
            )
        }
    )
    def get(self, request):
        """Get current visit count"""
        dao = VisitCountDAO()
        try:
            count = dao.get_count()
            return Response({'count': count})
        except Exception as e:
            return Response({'error': str(e)}, status=500)
        finally:
            del dao

    @swagger_auto_schema(
        operation_description="Increment visit count",
        responses={
            200: openapi.Response(
                description="Success",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={
                        'count': openapi.Schema(type=openapi.TYPE_INTEGER, description='Updated visit count'),
                    }
                )
            )
        }
    )
    def post(self, request):
        """Increment visit count"""
        dao = VisitCountDAO()
        try:
            count = dao.increment_count()
            return Response({'count': count})
        except Exception as e:
            return Response({'error': str(e)}, status=500)
        finally:
            del dao

class IncrementView(APIView):
    @swagger_auto_schema(
        operation_description="Increment visit count",
        responses={
            200: openapi.Response(
                description="Success",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={
                        'count': openapi.Schema(type=openapi.TYPE_INTEGER, description='Updated visit count'),
                    }
                )
            )
        }
    )
    def post(self, request):
        """Increment visit count"""
        dao = VisitCountDAO()
        try:
            count = dao.increment_count()
            return Response({'count': count})
        finally:
            del dao 
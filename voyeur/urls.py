from django.contrib import admin
from django.urls import path, re_path, include
from django.conf import settings
from rest_framework import permissions
from rest_framework.permissions import AllowAny
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
    openapi.Info(
        title="Voyeur API",
        default_version='v1',
        description="API documentation for Voyeur metrics collection service",
        terms_of_service="https://peoplesystem.tatdvsonorth.com/terms/",
        contact=openapi.Contact(email="contact@example.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=[AllowAny],
    authentication_classes=[],
    url=settings.SWAGGER_SETTINGS['DEFAULT_API_URL'],
)

# Base URL patterns
base_urlpatterns = [
    path('admin/', admin.site.urls),
    path('accounts/', include('django.contrib.auth.urls')),
    path('swagger.json', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('', include('visit.urls')),
]

# Wrap all URLs with /voyeur prefix
urlpatterns = [path('voyeur/', include(base_urlpatterns))] 
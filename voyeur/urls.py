from django.contrib import admin
from django.urls import path, re_path, include
from rest_framework import permissions
from rest_framework.permissions import AllowAny
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from django.conf import settings

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

urlpatterns = [
    path('admin/', admin.site.urls),
    # Authentication URLs - using Django's built-in auth URLs
    path('accounts/', include('django.contrib.auth.urls')),
g    # Swagger UI
    re_path(r'^swagger(?P<format>\.json|\.yaml)$', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    # Visit API
    path('', include('visit.urls')),
] 
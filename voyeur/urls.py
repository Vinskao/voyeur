from django.contrib import admin
from django.urls import path, re_path, include
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
    openapi.Info(
        title="Voyeur API",
        default_version='v1',
        description="API documentation for Voyeur metrics collection service",
        terms_of_service="https://www.google.com/policies/terms/",
        contact=openapi.Contact(email="contact@example.com"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

urlpatterns = [
    path('admin/', admin.site.urls),
    # Authentication URLs - using Django's built-in auth URLs
    path('accounts/', include('django.contrib.auth.urls')),
    # Swagger UI - with voyeur prefix for Ingress compatibility
    re_path(r'^voyeur/swagger(?P<format>\.json|\.yaml)$', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    path('voyeur/swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    # Visit API
    path('voyeur/', include('visit.urls')),
] 
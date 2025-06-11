from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from django.views.generic import RedirectView

schema_view = get_schema_view(
    openapi.Info(
        title="Voyeur API",
        default_version='v1',
        description="API documentation for Voyeur",
        terms_of_service="https://www.google.com/policies/terms/",
        contact=openapi.Contact(email="contact@voyeur.local"),
        license=openapi.License(name="BSD License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
    patterns=[
        path('voyeur/', include('visit.urls')),
    ],
)

# Base URL patterns
base_urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('visit.urls')),
    path('swagger.json', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
]

# Add static files serving in development
if settings.DEBUG:
    base_urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# Wrap all URLs with /voyeur prefix
urlpatterns = [path('voyeur/', include(base_urlpatterns))]

# Add redirect for root URL to Swagger UI
urlpatterns += [
    path('', RedirectView.as_view(url='/voyeur/swagger/', permanent=False), name='index'),
] 
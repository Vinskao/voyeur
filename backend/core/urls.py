from django.contrib import admin
from django.urls import path, include
from .views import metrics, server_info

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('apis.urls', namespace='apis')),
]
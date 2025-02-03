from django.urls import path
from . import views

app_name = 'apis'

urlpatterns = [
    path('hello', views.hello, name='hello'),
    path('metrics', views.metrics, name='metrics'),
    path('server-info', views.server_info, name='server-info'),
] 
from django.urls import path
from . import views
# We use the get_orm_metrics_view defined in apis/views.py
app_name = 'apis'

urlpatterns = [
    path('hello', views.hello, name='hello'),
    path('metrics', views.metrics, name='metrics'),
    path('server-info', views.server_info, name='server-info'),
    path('orm_metrics', views.orm_metrics_view, name="orm_metrics"),
    path('orm_metrics/delete', views.delete_all_documents, name="delete_all_documents"),
] 
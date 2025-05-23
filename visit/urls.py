from django.urls import path
from . import views
 
urlpatterns = [
    path('visit/count', views.get_visit_count, name='get_visit_count'),
    path('visit/increment', views.increment_visit_count, name='increment_visit_count'),
] 
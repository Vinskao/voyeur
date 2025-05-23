from django.urls import path
from . import views
 
urlpatterns = [
    path('voyeur/visit/count', views.get_visit_count, name='get_visit_count'),
    path('voyeur/visit/increment', views.increment_visit_count, name='increment_visit_count'),
] 
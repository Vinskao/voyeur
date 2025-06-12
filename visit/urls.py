from django.urls import path
from .views import VisitCountView, IncrementView, PushView

app_name = 'visit'

urlpatterns = [
    path('count/', VisitCountView.as_view(), name='visit_count'),
    path('increment/', IncrementView.as_view(), name='increment_count'),
    path('push/', PushView.as_view(), name='push'),
]
from django.urls import path
from .views import SymptomListCreateView

urlpatterns = [
    path('', SymptomListCreateView.as_view(), name='symptom-list-create'),
]

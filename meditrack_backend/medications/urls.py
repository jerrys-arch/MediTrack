from django.urls import path
from .views import MedicationListCreateView, MedicationRetrieveUpdateView

urlpatterns = [
    path('', MedicationListCreateView.as_view(), name='medication-list-create'),
    path('<int:id>/', MedicationRetrieveUpdateView.as_view(), name='medication-detail'),
]

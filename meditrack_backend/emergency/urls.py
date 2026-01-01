from django.urls import path
from .views import EmergencyContactListCreateView

urlpatterns = [
    path('contacts/', EmergencyContactListCreateView.as_view(), name='emergency_contacts'),
]

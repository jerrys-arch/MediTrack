from django.shortcuts import render

# Create your views here.
from rest_framework import generics, permissions
from .models import EmergencyContact
from .serializers import EmergencyContactSerializer

class EmergencyContactListCreateView(generics.ListCreateAPIView):
    serializer_class = EmergencyContactSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return EmergencyContact.objects.filter(user=self.request.user).order_by('-date_added')

    def perform_create(self, serializer):
        # If the new contact is primary, unset existing primary
        if serializer.validated_data.get('is_primary', False):
            EmergencyContact.objects.filter(user=self.request.user, is_primary=True).update(is_primary=False)
        serializer.save(user=self.request.user)

from django.shortcuts import render

# Create your views here.
from rest_framework import generics, permissions
from .models import Symptom
from .serializers import SymptomSerializer


class SymptomListCreateView(generics.ListCreateAPIView):
    serializer_class = SymptomSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Symptom.objects.filter(user=self.request.user).order_by('-date')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

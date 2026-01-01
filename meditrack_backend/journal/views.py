from django.shortcuts import render

# Create your views here.
from rest_framework import generics, permissions
from .models import Journal
from .serializers import JournalSerializer

class JournalListCreateView(generics.ListCreateAPIView):
    serializer_class = JournalSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Only return journals of the logged-in user
        return Journal.objects.filter(user=self.request.user).order_by('-date')

    def perform_create(self, serializer):
        # Save the logged-in user automatically
        serializer.save(user=self.request.user)

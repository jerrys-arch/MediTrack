from django.urls import path
from .views import JournalListCreateView

urlpatterns = [
    path('journals/', JournalListCreateView.as_view(), name='journal-list-create'),
]

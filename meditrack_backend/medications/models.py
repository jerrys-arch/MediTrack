from django.db import models
from django.conf import settings

class Medication(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='medications')
    name = models.CharField(max_length=255)
    dosage = models.CharField(max_length=100, blank=True, null=True)       # nullable & optional
    frequency = models.CharField(max_length=100, blank=True, null=True)
    time = models.TimeField(blank=True, null=True)
    reminder = models.BooleanField(default=False)
    taken = models.BooleanField(default=False)
    notes = models.TextField(blank=True, null=True)                         # nullable & optional
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.user.username}"

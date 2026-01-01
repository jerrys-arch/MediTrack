from django.db import models
from django.conf import settings

class Symptom(models.Model):
    MOOD_CHOICES = [
        ("😞", "Bad"),
        ("😐", "Okay"),
        ("😊", "Good"),
    ]

    PAIN_CHOICES = [
        ("Low", "Low"),
        ("Medium", "Medium"),
        ("High", "High"),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    date = models.DateTimeField(auto_now_add=True)
    mood = models.CharField(max_length=2, choices=MOOD_CHOICES)
    note = models.TextField()
    pain_level = models.CharField(max_length=6, choices=PAIN_CHOICES)
    tag = models.CharField(max_length=50, default="General")

    def __str__(self):
        return f"{self.user.username} - {self.mood} on {self.date.strftime('%Y-%m-%d')}"

    class Meta:
        ordering = ["-date"]

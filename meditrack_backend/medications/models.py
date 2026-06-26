from django.db import models
from django.conf import settings


class Medication(models.Model):
    FREQUENCY_DAILY = 'Daily'
    FREQUENCY_WEEKLY = 'Weekly'
    FREQUENCY_CUSTOM = 'Custom'

    DAY_CHOICES = [
        (0, 'Monday'),
        (1, 'Tuesday'),
        (2, 'Wednesday'),
        (3, 'Thursday'),
        (4, 'Friday'),
        (5, 'Saturday'),
        (6, 'Sunday'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='medications',
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_medications',
    )
    name = models.CharField(max_length=255)
    dosage = models.CharField(max_length=100, blank=True, null=True)
    frequency = models.CharField(max_length=100, blank=True, null=True)
    # Only used when frequency == 'Weekly'. 0=Monday ... 6=Sunday (Python's weekday() convention)
    day_of_week = models.PositiveSmallIntegerField(
        choices=DAY_CHOICES, blank=True, null=True
    )
    time = models.TimeField(blank=True, null=True)
    reminder = models.BooleanField(default=False)
    taken = models.BooleanField(default=False)
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    # Lets a caregiver/patient stop a medication without deleting history
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} - {self.user.username}"

    def is_due_today(self, today):
        """Returns True if this medication should have a dose log for `today`."""
        if not self.is_active or not self.time:
            return False
        if self.frequency == self.FREQUENCY_WEEKLY:
            if self.day_of_week is None:
                return False
            return today.weekday() == self.day_of_week
        # Daily and Custom both behave as daily for now
        return True
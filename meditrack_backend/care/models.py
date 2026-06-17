import uuid
from django.db import models
from django.conf import settings


class CareRelationship(models.Model):
    """Links a caregiver to a patient they manage."""

    STATUS_PENDING = 'pending'
    STATUS_ACTIVE = 'active'
    STATUS_DECLINED = 'declined'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_ACTIVE, 'Active'),
        (STATUS_DECLINED, 'Declined'),
    ]

    caregiver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='care_relationships',
        limit_choices_to={'role': 'caregiver'},
    )
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='patient_relationships',
        null=True,
        blank=True,
        limit_choices_to={'role': 'patient'},
    )
    # 6-character uppercase code the patient enters to accept the link
    invite_code = models.CharField(max_length=8, unique=True, editable=False)
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default=STATUS_PENDING,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        # A caregiver can only have one active relationship per patient
        unique_together = ('caregiver', 'patient')

    def save(self, *args, **kwargs):
        if not self.invite_code:
            self.invite_code = self._generate_code()
        super().save(*args, **kwargs)

    @staticmethod
    def _generate_code():
        import random, string
        while True:
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
            if not CareRelationship.objects.filter(invite_code=code).exists():
                return code

    def __str__(self):
        return f"{self.caregiver.email} → {self.patient.email if self.patient else 'pending'} [{self.status}]"


class DoseLog(models.Model):
    """Records every individual dose event for a medication."""

    STATUS_PENDING = 'pending'
    STATUS_TAKEN = 'taken'
    STATUS_MISSED = 'missed'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_TAKEN, 'Taken'),
        (STATUS_MISSED, 'Missed'),
    ]

    medication = models.ForeignKey(
        'medications.Medication',
        on_delete=models.CASCADE,
        related_name='dose_logs',
    )
    patient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='dose_logs',
    )
    scheduled_time = models.DateTimeField()
    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default=STATUS_PENDING,
    )
    confirmed_at = models.DateTimeField(null=True, blank=True)
    # How many minutes after scheduled_time before marking missed
    grace_minutes = models.PositiveIntegerField(default=60)

    class Meta:
        ordering = ['-scheduled_time']
        # Only one log per medication per scheduled time
        unique_together = ('medication', 'scheduled_time')

    def __str__(self):
        return f"{self.medication.name} | {self.scheduled_time:%Y-%m-%d %H:%M} | {self.status}"

    @property
    def is_overdue(self):
        from django.utils import timezone
        from datetime import timedelta
        if self.status != self.STATUS_PENDING:
            return False
        deadline = self.scheduled_time + timedelta(minutes=self.grace_minutes)
        return timezone.now() > deadline
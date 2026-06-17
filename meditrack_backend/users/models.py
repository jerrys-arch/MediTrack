from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    ROLE_CAREGIVER = 'caregiver'
    ROLE_PATIENT = 'patient'
    ROLE_CHOICES = [
        (ROLE_CAREGIVER, 'Caregiver'),
        (ROLE_PATIENT, 'Patient'),
    ]

    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=255)
    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default=ROLE_PATIENT,
    )

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def __str__(self):
        return f"{self.email} ({self.role})"

    @property
    def is_caregiver(self):
        return self.role == self.ROLE_CAREGIVER

    @property
    def is_patient(self):
        return self.role == self.ROLE_PATIENT
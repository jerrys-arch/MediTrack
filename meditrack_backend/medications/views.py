from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied, ValidationError

from care.models import CareRelationship, DoseLog
from .models import Medication
from .serializers import MedicationSerializer

User = get_user_model()


class MedicationListCreateView(generics.ListCreateAPIView):
    serializer_class = MedicationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_caregiver:
            return Medication.objects.filter(
                created_by=user
            ).order_by('-created_at')
        return Medication.objects.filter(
            user=user
        ).order_by('-created_at')

    def perform_create(self, serializer):
        user = self.request.user
        patient_id = serializer.validated_data.pop('patient_id', None)

        if user.is_caregiver:
            if not patient_id:
                raise ValidationError(
                    {'patient_id': 'Caregivers must specify a patient_id.'}
                )

            is_linked = CareRelationship.objects.filter(
                caregiver=user,
                patient_id=patient_id,
                status=CareRelationship.STATUS_ACTIVE,
            ).exists()

            if not is_linked:
                raise PermissionDenied('You are not linked with this patient.')

            try:
                patient = User.objects.get(pk=patient_id, role='patient')
            except User.DoesNotExist:
                raise ValidationError({'patient_id': 'Patient not found.'})

            medication = serializer.save(user=patient, created_by=user)
        else:
            medication = serializer.save(user=user, created_by=None)

        # Always try to create a DoseLog if time is set
        if medication.time:
            _create_dose_log_for_today(medication)


def _create_dose_log_for_today(medication):
    """Creates a DoseLog for today regardless of whether time has passed."""
    today = timezone.localdate()
    scheduled_dt = timezone.make_aware(
        timezone.datetime.combine(today, medication.time)
    )

    # Create even if time already passed today so it shows up immediately
    DoseLog.objects.get_or_create(
        medication=medication,
        scheduled_time=scheduled_dt,
        defaults={
            'patient': medication.user,
            'status': DoseLog.STATUS_PENDING,
        },
    )


class MedicationRetrieveUpdateView(generics.RetrieveUpdateAPIView):
    serializer_class = MedicationSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'id'

    def get_queryset(self):
        user = self.request.user
        if user.is_caregiver:
            return Medication.objects.filter(created_by=user)
        return Medication.objects.filter(user=user)

    def perform_update(self, serializer):
        serializer.validated_data.pop('patient_id', None)
        serializer.save()
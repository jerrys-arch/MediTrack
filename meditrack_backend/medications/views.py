from django.contrib.auth import get_user_model
from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied, ValidationError

from care.models import CareRelationship
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

            serializer.save(user=patient, created_by=user)
        else:
            serializer.save(user=user, created_by=None)

        # NOTE: We no longer create a DoseLog here.
        # Dose logs are now generated lazily — see care/views.py
        # ensure_todays_dose_logs(), which runs whenever the patient's or
        # caregiver's dashboard is loaded. This means a medication shows
        # up correctly every day it's due, not just the day it was created.


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
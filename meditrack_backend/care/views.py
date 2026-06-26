from datetime import datetime
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import CareRelationship, DoseLog
from .serializers import (
    CareRelationshipSerializer,
    AcceptInviteSerializer,
    DoseLogSerializer,
    ConfirmDoseSerializer,
)


# ── Lazy dose log generation ───────────────────────────────────────────────
# Called whenever a patient's or caregiver's dashboard is loaded.
# Ensures "today's" dose log exists for every active medication that is
# due today, based on its frequency (Daily / Weekly / Custom).

def ensure_todays_dose_logs(patient):
    """
    Creates any missing DoseLog rows for `patient` for today, based on
    each of their medications' frequency and scheduled time.
    Safe to call repeatedly — uses get_or_create so it never duplicates.
    """
    from medications.models import Medication  # local import avoids circular import

    today = timezone.localdate()

    medications = Medication.objects.filter(user=patient, is_active=True)

    for medication in medications:
        if not medication.is_due_today(today):
            continue

        scheduled_dt = timezone.make_aware(
            datetime.combine(today, medication.time)
        )

        DoseLog.objects.get_or_create(
            medication=medication,
            scheduled_time=scheduled_dt,
            defaults={
                'patient': patient,
                'status': DoseLog.STATUS_PENDING,
            },
        )


# ── Caregiver: create an invite ───────────────────────────────────────────────

class CreateInviteView(generics.CreateAPIView):
    """Caregiver calls this to generate an invite code."""
    serializer_class = CareRelationshipSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        if not self.request.user.is_caregiver:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("Only caregivers can create invites.")
        serializer.save(caregiver=self.request.user)


# ── Caregiver: list their patients ────────────────────────────────────────────

class MyPatientsView(generics.ListAPIView):
    """Returns all active patient relationships for the logged-in caregiver."""
    serializer_class = CareRelationshipSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return CareRelationship.objects.filter(
            caregiver=self.request.user,
            status=CareRelationship.STATUS_ACTIVE,
        ).select_related('patient')


# ── Patient: accept an invite ─────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def accept_invite(request):
    """Patient submits their invite code to link with a caregiver."""
    if not request.user.is_patient:
        return Response(
            {'error': 'Only patients can accept invites.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    serializer = AcceptInviteSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    code = serializer.validated_data['invite_code']
    rel = CareRelationship.objects.get(invite_code=code, status=CareRelationship.STATUS_PENDING)
    rel.patient = request.user
    rel.status = CareRelationship.STATUS_ACTIVE
    rel.accepted_at = timezone.now()
    rel.save()

    return Response(
        {'message': 'Linked successfully.', 'caregiver': rel.caregiver.full_name},
        status=status.HTTP_200_OK,
    )


# ── Patient: view today's doses ───────────────────────────────────────────────

class MyDosesView(generics.ListAPIView):
    """Patient sees their pending/today's dose logs."""
    serializer_class = DoseLogSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Lazily create today's dose logs before returning them
        ensure_todays_dose_logs(self.request.user)

        today = timezone.localdate()
        return DoseLog.objects.filter(
            patient=self.request.user,
            scheduled_time__date=today,
        ).select_related('medication')


# ── Patient: confirm a dose ───────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def confirm_dose(request):
    """Patient marks a dose as taken."""
    serializer = ConfirmDoseSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    log = DoseLog.objects.get(
        pk=serializer.validated_data['dose_log_id'],
        patient=request.user,
        status=DoseLog.STATUS_PENDING,
    )
    log.status = DoseLog.STATUS_TAKEN
    log.confirmed_at = timezone.now()
    log.save()

    return Response({'message': 'Dose confirmed.', 'confirmed_at': log.confirmed_at})


# ── Caregiver: view a patient's doses ─────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def patient_doses(request, patient_id):
    """Caregiver views dose logs for one of their patients."""
    is_linked = CareRelationship.objects.filter(
        caregiver=request.user,
        patient_id=patient_id,
        status=CareRelationship.STATUS_ACTIVE,
    ).exists()

    if not is_linked:
        return Response(
            {'error': 'You do not manage this patient.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    # Lazily create today's dose logs for this patient before returning them
    from django.contrib.auth import get_user_model
    User = get_user_model()
    patient = User.objects.get(pk=patient_id)
    ensure_todays_dose_logs(patient)

    today = timezone.localdate()
    logs = DoseLog.objects.filter(
        patient_id=patient_id,
        scheduled_time__date=today,
    ).select_related('medication')

    return Response(DoseLogSerializer(logs, many=True).data)


# ── Utility: mark overdue doses as missed ─────────────────────────────────────

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_missed_doses(request):
    """
    Marks all pending overdue doses as missed.
    In production call this from a scheduled job, not a user-facing endpoint.
    """
    pending = DoseLog.objects.filter(status=DoseLog.STATUS_PENDING)
    missed_ids = [log.pk for log in pending if log.is_overdue]
    DoseLog.objects.filter(pk__in=missed_ids).update(status=DoseLog.STATUS_MISSED)
    return Response({'marked_missed': len(missed_ids)})
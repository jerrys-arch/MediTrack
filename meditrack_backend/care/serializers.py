from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import CareRelationship, DoseLog

User = get_user_model()


class PatientSummarySerializer(serializers.ModelSerializer):
    """Minimal patient info shown on caregiver dashboard."""
    name = serializers.CharField(source='full_name')

    class Meta:
        model = User
        fields = ('id', 'name', 'email')


class CareRelationshipSerializer(serializers.ModelSerializer):
    patient_detail = PatientSummarySerializer(source='patient', read_only=True)

    class Meta:
        model = CareRelationship
        fields = (
            'id', 'invite_code', 'status',
            'patient', 'patient_detail',
            'created_at', 'accepted_at',
        )
        read_only_fields = ('invite_code', 'status', 'created_at', 'accepted_at')


class AcceptInviteSerializer(serializers.Serializer):
    """Patient submits their 6-char code to link with a caregiver."""
    invite_code = serializers.CharField(max_length=8, min_length=6)

    def validate_invite_code(self, value):
        try:
            rel = CareRelationship.objects.get(
                invite_code=value.upper(),
                status=CareRelationship.STATUS_PENDING,
            )
        except CareRelationship.DoesNotExist:
            raise serializers.ValidationError("Invalid or already used invite code.")
        return value.upper()


class DoseLogSerializer(serializers.ModelSerializer):
    medication_name = serializers.CharField(source='medication.name', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)

    class Meta:
        model = DoseLog
        fields = (
            'id', 'medication', 'medication_name',
            'scheduled_time', 'status',
            'confirmed_at', 'is_overdue',
        )
        read_only_fields = ('confirmed_at', 'is_overdue')


class ConfirmDoseSerializer(serializers.Serializer):
    """Patient confirms they took a dose."""
    dose_log_id = serializers.IntegerField()

    def validate_dose_log_id(self, value):
        try:
            log = DoseLog.objects.get(pk=value, status=DoseLog.STATUS_PENDING)
        except DoseLog.DoesNotExist:
            raise serializers.ValidationError("Dose log not found or already confirmed.")
        return value
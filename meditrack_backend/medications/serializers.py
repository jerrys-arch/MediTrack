from rest_framework import serializers
from .models import Medication


class MedicationSerializer(serializers.ModelSerializer):
    time = serializers.TimeField(
        format='%H:%M',
        input_formats=['%H:%M', '%H:%M:%S'],
        required=False,
        allow_null=True,
    )
    patient_id = serializers.IntegerField(write_only=True, required=False)

    class Meta:
        model = Medication
        fields = [
            'id',
            'name',
            'dosage',
            'frequency',
            'day_of_week',
            'time',
            'reminder',
            'taken',
            'is_active',
            'notes',
            'created_at',
            'patient_id',
        ]

    def validate(self, data):
        frequency = data.get('frequency')
        day_of_week = data.get('day_of_week')

        if frequency == Medication.FREQUENCY_WEEKLY and day_of_week is None:
            raise serializers.ValidationError(
                {'day_of_week': 'Please select a day of the week for weekly medications.'}
            )
        return data
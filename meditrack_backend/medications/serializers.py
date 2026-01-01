from rest_framework import serializers
from .models import Medication

class MedicationSerializer(serializers.ModelSerializer):
    time = serializers.TimeField(
        format="%H:%M",
        input_formats=["%H:%M", "%H:%M:%S"],
        required=False,
        allow_null=True
    )

    class Meta:
        model = Medication
        fields = [
            'id',
            'name',
            'dosage',
            'frequency',
            'time',
            'reminder',
            'taken',
            'notes',
            'created_at',
        ]

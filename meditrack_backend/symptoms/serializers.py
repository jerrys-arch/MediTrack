from rest_framework import serializers
from .models import Symptom

class SymptomSerializer(serializers.ModelSerializer):
    date = serializers.SerializerMethodField()

    class Meta:
        model = Symptom
        fields = [
            'id',
            'date',
            'mood',
            'note',
            'tag',
            'pain_level',
        ]
        read_only_fields = ['id', 'date']

    def get_date(self, obj):
        if obj.date:
            return obj.date.strftime("%b %d, %Y • %I:%M %p")
            # Example: "Jan 01, 2025 • 02:23 PM"
        return ""

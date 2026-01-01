from django.contrib import admin
from .models import Medication

@admin.register(Medication)
class MedicationAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'name', 'dosage', 'time', 'frequency', 'reminder', 'taken', 'created_at')
    list_filter = ('frequency', 'reminder', 'taken', 'created_at')
    search_fields = ('name', 'dosage', 'notes', 'user__username')

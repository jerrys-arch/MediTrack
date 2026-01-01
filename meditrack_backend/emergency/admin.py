from django.contrib import admin
from .models import EmergencyContact

@admin.register(EmergencyContact)
class EmergencyContactAdmin(admin.ModelAdmin):
    list_display = ('name', 'relationship', 'phone_number', 'is_primary', 'user', 'date_added')
    list_filter = ('is_primary',)
    search_fields = ('name', 'phone_number', 'relationship', 'user__username')

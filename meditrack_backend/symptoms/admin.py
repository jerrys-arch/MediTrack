from django.contrib import admin
from .models import Symptom

@admin.register(Symptom)
class SymptomAdmin(admin.ModelAdmin):
    list_display = ('user', 'date', 'mood', 'pain_level', 'tag', 'note')
    list_filter = ('mood', 'pain_level', 'date', 'user')
    search_fields = ('note', 'tag', 'user__username')
    ordering = ('-date',)

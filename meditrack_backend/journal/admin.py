from django.contrib import admin

# Register your models here.
from django.contrib import admin
from .models import Journal

@admin.register(Journal)
class JournalAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'date')
    search_fields = ('title', 'description', 'user__username')
    list_filter = ('date',)

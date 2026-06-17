from django.urls import path
from .views import (
    CreateInviteView,
    MyPatientsView,
    MyDosesView,
    accept_invite,
    confirm_dose,
    patient_doses,
    mark_missed_doses,
)

urlpatterns = [
    # Caregiver
    path('invite/', CreateInviteView.as_view()),          # POST — create invite
    path('patients/', MyPatientsView.as_view()),          # GET  — list my patients
    path('patient/<int:patient_id>/doses/', patient_doses),  # GET  — view patient doses

    # Patient
    path('accept-invite/', accept_invite),                # POST — enter invite code
    path('doses/', MyDosesView.as_view()),                # GET  — my today's doses
    path('doses/confirm/', confirm_dose),                 # POST — mark dose taken

    # Utility (call from a cron job in production)
    path('doses/mark-missed/', mark_missed_doses),        # POST — mark overdue as missed
]
# MediTrack

**MediTrack** is a full-stack mobile health management application built with **Flutter** (frontend) and **Django REST Framework** (backend). It allows users to track medications, monitor symptoms, maintain personal health journals, and manage emergency contacts. The app is designed for simplicity, usability, and reliability, making it suitable for students, patients, and general users.

---

## Features

### Frontend (Flutter)
- User authentication (login & signup) with secure JWT tokens
- Home dashboard with quick actions
- Medication tracker: add, update, delete, and view medications
- Symptom tracker: log daily symptoms and monitor trends
- Health journal: add private entries and reflections
- Emergency contacts: add and view contacts
- Responsive for mobile (Android), with potential for Web and iOS in the future
- User-friendly interface

### Backend (Django REST Framework)
- User authentication and management
- Medication, symptom, and health journal management
- Emergency contact management
- SQLite database (can be switched to PostgreSQL/MySQL)
- Live deployment at Render: `https://meditrack-7.onrender.com`

---

## Installation & Usage

### Using the APK (Android)
1. Copy the `app-release.apk` file to your device.
2. Enable installation from unknown sources in your device settings.
3. Open the APK file to install.
4. Launch the app.
5. Register a new account or log in with existing credentials.
6. Internet connection is required as the app communicates with the live backend.

---

### Running from Source (Flutter)

#### Prerequisites
- Flutter SDK
- Python 3.10+
- Pip
- Git
- Optional: PostgreSQL/MySQL for production

#### Backend Setup (Django)
```bash
cd meditrack_backend
python -m venv venv        # Create virtual environment
# Activate virtual environment
# Windows
venv\Scripts\activate
# Mac/Linux
source venv/bin/activate

pip install -r requirements.txt
python manage.py migrate   # Apply migrations
python manage.py runserver # Start server
Frontend Setup (Flutter)
bash
Copy code
cd meditrack_app
flutter pub get            # Install dependencies
flutter run                # Run app on connected device
flutter run -d chrome      # Run app in web browser
API Communication:

All API requests use JWT authentication:

makefile
Copy code
Authorization: Bearer <token>
ApiConfig manages backend URLs for local, emulator, and live deployments.

Backend API Overview
Live backend URL: https://meditrack-7.onrender.com

Feature	Endpoint
Login	/api/auth/login/
Register	/api/auth/register/
Medications	/api/medications/
Symptoms	/api/symptoms/
Journal	/api/journal/
Emergency Contacts	/api/emergency/

Visiting the root URL confirms the backend is running:
https://meditrack-7.onrender.com/

Future Improvements
Medication Notifications & Reminders

Push notifications based on medication schedules.

SOS / Emergency Button

Call emergency contacts or send SMS alerts with location.

Offline Mode

Add data offline and sync automatically when online.

Health Analytics

Charts for adherence and symptom trends.

Enhanced Security

Biometric login (fingerprint/face ID) and improved session management.

Role-Based Access

Doctors can view patient data with permissions.

Cross-Platform Expansion

Full iOS and Web support with consistent UI.

Cloud Backup & Data Export

Export health data as PDF/CSV and cloud backups.

Limitations
Notifications and SOS button are not implemented yet.

Internet connection is required for most features.

Currently Android-only.

Conclusion
Meditrack is a functional mobile health management application that demonstrates the integration of mobile development, backend APIs, authentication, and cloud deployment. It meets its academic objectives and provides a strong foundation for future enhancements such as notifications, emergency handling, and analytics.

License
MIT License © 2025











# MediTrack

**MediTrack** is a full-stack health management app built with **Flutter** (frontend) and **Django** (backend). It helps users track medications, symptoms, doctor visits, prescriptions, and health notes.  

---

## Features

### Frontend (Flutter)
- User authentication (login & signup)
- Home dashboard with quick actions
- Medication tracker
- Symptom tracker
- Health journal (visits, prescriptions, notes)
- Emergency contacts
- Settings & profile management
- Responsive for mobile, web, and desktop
- Add, update, and view health data in a user-friendly interface

### Backend (Django)
- User authentication and management
- Medication management
- Symptom tracking
- Health journal management
- Emergency contacts management
- SQLite database (can be switched to PostgreSQL/MySQL)

---

## Getting Started

### Prerequisites
- **Flutter SDK**
- **Python 3.10+**
- **Pip**
- **Git**
- Optional: **PostgreSQL/MySQL** for production

### Backend Setup (Django)
1. Navigate to backend folder:
   ```bash
   cd meditrack_backend/meditrack
Create virtual environment:

python -m venv venv


Activate it:

Windows: venv\Scripts\activate

Mac/Linux: source venv/bin/activate

Install dependencies:

pip install -r requirements.txt


Apply migrations:

python manage.py migrate


Run server:

python manage.py runserver

Frontend Setup (Flutter)

Navigate to Flutter project:

cd meditrack_app


Get dependencies:

flutter pub get


Run app:

flutter run


For web:

flutter run -d chrome


All requests require JWT token in the header:
Authorization: Bearer <token>

Notes

ApiConfig automatically switches URLs for localhost, Android emulator, and web.

For production, update ApiConfig to point to your deployed backend.

Exclude db.sqlite3 from production or use PostgreSQL/MySQL.

License

MIT License © 2025

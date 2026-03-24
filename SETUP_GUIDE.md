# No To Distraction - Setup & Integration Guide

Complete production-ready authentication and onboarding system for Flutter + FastAPI + MongoDB.

## Overview

This full-stack application provides:
- **Backend (Python FastAPI)**: Secure REST API with JWT authentication, bcrypt password hashing, and MongoDB integration
- **Frontend (Flutter)**: Modern UI with secure token storage, state management using Provider, and comprehensive onboarding flow
- **Authentication Flow**: Splash → Login/Signup → Onboarding → Home
- **Security**: JWT tokens, password hashing, secure storage, form validation

## Project Structure

```
no_to_distraction/
├── backend/                      # FastAPI backend
│   ├── app/
│   │   ├── main.py              # FastAPI application & endpoints
│   │   ├── config.py            # Configuration & settings
│   │   ├── database.py          # MongoDB connection
│   │   ├── models.py            # User model
│   │   ├── schemas.py           # Pydantic validation schemas
│   │   ├── auth.py              # JWT & password utilities
│   │   └── __init__.py
│   ├── requirements.txt          # Python dependencies
│   ├── .env                      # Environment variables
│   └── main.py                   # Entry point
│
└── lib/                           # Flutter frontend
    ├── config/
    │   └── app_config.dart       # Constants & configuration
    ├── models/
    │   ├── user.dart             # User & onboarding models
    │   └── auth.dart             # Auth request/response models
    ├── services/
    │   ├── api_service.dart      # HTTP client & API calls
    │   └── secure_storage_service.dart  # Secure token storage
    ├── providers/
    │   └── auth_provider.dart    # Auth state management
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── login_screen.dart
    │   ├── signup_screen.dart
    │   ├── onboarding_screen.dart
    │   └── home_screen.dart
    ├── widgets/
    │   └── form_widgets.dart     # Reusable widgets
    ├── theme/
    │   └── app_theme.dart        # App theming
    └── main.dart                 # App entry point
```

## Backend Setup

### Prerequisites
- Python 3.10+
- MongoDB (local or cloud - MongoDB Atlas)

### Installation

1. **Set up Python environment**:
```bash
cd backend
python -m venv venv
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

2. **Install dependencies**:
```bash
pip install -r requirements.txt
```

3. **Configure MongoDB**:
   - **Local MongoDB**: Start your MongoDB server (default: `mongodb://localhost:27017`)
   - **MongoDB Atlas** (cloud): Update `MONGODB_URL` in `.env` with your connection string

4. **Update `.env` file**:
```env
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=no_to_distraction_db
JWT_SECRET_KEY=your-super-secret-key-change-in-production
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

> ⚠️ **Important**: Change `JWT_SECRET_KEY` to a secure random string in production!

5. **Run the server**:
```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`.

**API Documentation** (auto-generated):
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Backend API Endpoints

### Authentication

**Register User** `POST /api/v1/auth/register`
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "name": "John Doe"
}
```

**Login User** `POST /api/v1/auth/login`
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Response**:
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "user": {
    "id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "name": "John Doe",
    "onboarding_completed": false,
    "created_at": "2026-03-18T10:00:00"
  }
}
```

### Onboarding

**Submit Preferences** `POST /api/v1/onboarding` (Protected)
```json
{
  "daily_focus_goal_minutes": 120,
  "study_time_start": "09:00",
  "study_time_end": "17:00",
  "sleep_time_start": "22:00",
  "sleep_time_end": "07:00",
  "institution_time_start": "09:00",
  "institution_time_end": "17:00"
}
```

**Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

## Frontend Setup

### Prerequisites
- Flutter SDK 3.10+
- A mobile device or emulator

### Installation

1. **Get dependencies**:
```bash
flutter pub get
```

2. **Update API Base URL** (if not using localhost):
   - Edit `lib/config/app_config.dart`
   - Update `baseUrl` to your backend URL:
   ```dart
   static const String baseUrl = 'http://your-backend-url:8000/api/v1';
   ```

3. **Run the app**:
```bash
# Android emulator or device
flutter run -d emulator-5554

# iOS simulator or device
flutter run -d all

# Web
flutter run -d chrome

# Specific device
flutter devices  # List available devices
flutter run -d <device_id>
```

### Build for Production

**Android**:
```bash
flutter build apk --release
# Or for App Bundle:
flutter build appbundle --release
```

**iOS**:
```bash
flutter build ios --release
```

**Web**:
```bash
flutter build web --release
```

## Frontend Architecture

### State Management (Provider)
The app uses `Provider` for state management with a single `AuthProvider` that manages:
- User authentication state
- Login/signup/logout actions
- Onboarding completion
- Error handling
- Loading states

### Security Features
- **Secure Token Storage**: Tokens stored using `flutter_secure_storage` (encrypted)
- **JWT Authentication**: All API requests include bearer token
- **Password Validation**: 
  - Min 8 characters
  - At least 1 uppercase letter
  - At least 1 number
  - Real-time strength indicator
- **Email Validation**: RFC 5322 compliant email validation
- **Form Validation**: Client-side validation on all inputs

### Navigation Flow
```
Splash Screen (Loading)
    ↓
[Check Authentication]
    ├─ Not Authenticated → Login Screen
    │   ├─ New User → Signup Screen → Onboarding Screen
    │   └─ Existing User → Home Screen
    │
    ├─ Authenticated, Not Onboarded → Onboarding Screen
    │   └─ After Onboarding → Home Screen
    │
    └─ Fully Authenticated → Home Screen
```

## Testing the Integration

### Manual Testing Steps

1. **Start the backend**:
```bash
cd backend
venv\Scripts\activate  # or source venv/bin/activate
python -m uvicorn app.main:app --reload
```

2. **Open API docs**:
   - Navigate to `http://localhost:8000/docs`
   - Test endpoints manually

3. **Start the Flutter app**:
```bash
flutter run
```

4. **Test Flow**:
   - **Sign up**: Enter name, email, password
   - **Verify**: Check password strength indicator
   - **Onboarding**: Set focus goals and schedule
   - **Home**: View welcome screen and quick actions
   - **Logout**: Use menu to logout and return to login

### Common Issues & Solutions

**Issue**: "Connection refused" error
- **Solution**: Ensure backend is running on `localhost:8000`
- Update `AppConfig.baseUrl` to match your backend URL

**Issue**: "Invalid email" validation
- **Solution**: Enter a valid email format (e.g., user@example.com)

**Issue**: "Password must contain..." error
- **Solution**: Password needs uppercase, lowercase, and number (min 8 chars)

**Issue**: MongoDB connection error
- **Solution**: 
  - Ensure MongoDB is running: `mongod`
  - Or update `MONGODB_URL` in `.env` with your MongoDB Atlas connection string

**Issue**: Token expiration (401 error after 30 mins)
- **Solution**: User will be automatically logged out and redirected to login screen
- Update `ACCESS_TOKEN_EXPIRE_MINUTES` in `.env` to extend session duration

## Production Considerations

### Backend
1. **Change JWT Secret**: Generate a random 32+ character string
   ```python
   import secrets
   secrets.token_urlsafe(32)
   ```

2. **CORS Configuration**: Restrict to your frontend URL:
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["https://yourfrontend.com"],
       ...
   )
   ```

3. **Environment Variables**: Use a secret manager (e.g., AWS Secrets Manager, HashiCorp Vault)

4. **Database Security**:
   - Enable MongoDB authentication
   - Use encrypted connections (TLS)
   - Create database indexes for performance

5. **Rate Limiting**: Add rate limiting to prevent brute force attacks
   ```python
   from slowapi import Limiter
   limiter = Limiter(key_func=get_remote_address)
   ```

6. **API Versioning**: Already implemented (`/api/v1/`)

7. **Logging & Monitoring**: Use cloud logging (e.g., CloudWatch, DataDog)

### Frontend
1. **API Base URL**: Use environment-specific URLs
   ```dart
   static const String baseUrl = const bool.fromEnvironment('API_URL') 
       ?? 'https://api.productionh.com/api/v1';
   ```

2. **Build Optimization**: Enable code obfuscation
   ```bash
   flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
   ```

3. **Offline Support**: Add offline caching with `hive_flutter`

4. **Crash Reporting**: Integrate `firebase_crashlytics` or `sentry_flutter`

## Next Steps

1. **Add more features**:
   - Profile management screen
   - Focus timer functionality
   - Analytics/statistics dashboard
   - Notification system
   - Push notifications for reminders

2. **Enhance security**:
   - Two-factor authentication (2FA)
   - Email verification
   - Password reset functionality
   - Device-based authentication

3. **Optimize performance**:
   - Add caching strategies
   - Implement pagination for data
   - Optimize database queries with proper indexing

4. **Add testing**:
   - Unit tests for models and services
   - Widget tests for UI components
   - Integration tests for auth flow
   - Backend API tests with pytest

## Support & Resources

### Official Documentation
- [FastAPI](https://fastapi.tiangolo.com/)
- [Flutter](https://flutter.dev/docs)
- [MongoDB](https://docs.mongodb.com/)
- [JWT](https://jwt.io/)
- [Provider Package](https://pub.dev/packages/provider)

### Key Dependencies Used

**Backend**:
- FastAPI 0.104.1
- Pydantic 2.5.0
- PyMongo 4.6.0
- python-jose[cryptography] 3.3.0
- passlib[bcrypt] 1.7.4

**Frontend**:
- provider: ^6.4.0
- http: ^1.1.0
- flutter_secure_storage: ^9.0.0
- email_validator: ^2.1.17
- shared_preferences: ^2.2.2

## License

This project is provided as-is for educational and development purposes.

---

**Created**: March 18, 2026  
**Version**: 1.0.0  
**Status**: Production Ready

# No To Distraction (Synapse) - Setup & Integration Guide

Comprehensive documentation for the 'Synapse' project—a cross-platform productivity application featuring short-form video addiction mitigation (Block & Deduct), secure authentication, and gamification.

## Overview

Synapse is a multi-layered ecosystem designed to reduce cognitive load and enhance focus:
- **Backend (Python FastAPI)**: High-performance, modular API with JWT persistence (30 days), timezone-aware datetime logic, and MongoDB Atlas/Local support.
- **Frontend (Flutter)**: Modern, ultra-minimalist UI with state management via Provider and secure local storage.
- **Native Engine (Android/Kotlin)**: Modularized Accessibility Service for real-time app scanning, detection (Reels/Shorts), and point-based screen blocking.

---

## Current Project Structure

### 1. Backend (FastAPI)
The backend uses a modular, scalable router-based architecture:
```
backend/
├── app/
│   ├── routers/             # API Endpoint Modules
│   │   ├── auth.py         # Registration, Login, Email Verification
│   │   ├── stats.py        # Focus Sessions, Block Events, Analytics
│   │   ├── onboarding.py   # User Preference Management
│   │   └── leaderboard.py  # Global Ranking Calculations
│   ├── utils/              # Business Logic & Helpers
│   │   ├── auth_utils.py   # Token generation & verification logic
│   │   └── stats_utils.py  # Data aggregation & analytics processing
│   ├── models/             # Database Document Definitions
│   ├── schemas/            # Pydantic Request/Response Validation
│   ├── core/               # App Lifecycle & Global Constants
│   ├── db/                 # MongoDB Database Connection
│   ├── auth.py             # Security Configuration (JWT, Bcrypt)
│   ├── config.py           # Environment-based Application Settings
│   ├── email_service.py    # SMTP Integration for Communications
│   └── main.py             # FastAPI entry point & Middleware setup
├── .env                    # Deployment Environment Variables
└── requirements.txt        # Python Dependency Management
```

### 2. Frontend (Flutter)
A clean, service-oriented architecture:
```
lib/
├── config/                 # Application Constants (API URLs)
├── services/               # Shared logic (API Client, Secure Storage)
├── providers/              # Global State (Auth, Permissions, Theme)
├── models/                 # Dart Data Objects
├── screens/                # UI Layer (Auth, Onboarding, Home)
├── widgets/                # Atomic UI Components & Common Elements
└── main.dart               # App initialization (Services & Bridges)
```

### 3. Native Android (Kotlin)
The heavy-lifting engine for monitoring and blocking:
```
android/app/src/main/kotlin/com/example/no_to_distraction/
├── ShortVideoAccessibilityService.kt  # Main monitoring service
├── ScannerEngine.kt                   # Reels/Shorts detection algorithm
├── OverlayManager.kt                  # UI blocking (System Alerts)
├── StorageManager.kt                  # Native-side persistence
├── ReelDetectionChannelBridge.kt      # MethodChannel Bridges
└── MainActivity.kt                    # Platform-side bridge initialization
```

---

## Environment Setup

### 1. Backend Configuration
**Prerequisites**: Python 3.12+ (confirmed compatible up to 3.14) and MongoDB (Atlas or Local).

1. **Virtual Environment**:
   ```bash
   cd backend
   python -m venv .venv
   .venv\Scripts\activate  # Windows
   ```

2. **Installation**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Environment Variables (`.env`)**:
   Create a `.env` in the `backend/` directory:
   ```env
   # Database Configurations
   MONGODB_URL=mongodb+srv://<user>:<password>@cluster0.mongodb.net/
   DATABASE_NAME=no_to_distraction_db

   # Security (JWT)
   JWT_SECRET_KEY=YOUR_SECURE_32_CHAR_SECRET
   JWT_ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=43200  # 30 Days persistence

   # SMTP Setup (Gmail Example)
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=465
   SMTP_USERNAME=your-email@gmail.com
   SMTP_PASSWORD=your-google-app-password  # REQUIRED: Use 'App Passwords'
   SMTP_FROM_EMAIL=your-email@gmail.com
   SMTP_USE_SSL=true
   ```

4. **Service Execution**:
   ```bash
   python -m uvicorn app.main:app --reload --host 0.0.0.0
   ```

### 2. Frontend Setup
**Prerequisites**: Flutter 3.10+ (Stable Channel).

1. **Dependencies**:
   ```bash
   flutter pub get
   ```

2. **API Configuration**:
   Update `lib/config/app_config.dart` with your machine's local IP or production URL:
   ```dart
   static const String baseUrl = 'http://192.168.x.x:8000/api/v1'; // Use IP for real devices
   ```

3. **Execution**:
   ```bash
   flutter run
   ```

---

## Core Mechanism: Block & Deduct

The "Synapse" app's primary feature is the ability to monitor and block distracting short-form video content (Reels/Shorts).

### How it works:
1. **Detection**: `ScannerEngine` (Native Kotlin) monitors screen activity via Accessibility API.
2. **Bridge**: If a distracting app/video is detected, a call is made via `MethodChannel` (`synapse/native_channel`) to the Flutter side.
3. **Validation**: Flutter's `AuthProvider` checks the user's available points and session state.
4. **Deduction**: Points are deducted on the backend via the `/stats/events/block-screen` endpoint.
5. **Action**: Flutter directs the Native side to trigger `OverlayManager` to render a minimalist blocking screen.

---

## Critical Permissions (Android Only)

Because this app uses system-level monitoring, the following must be manually enabled:

1. **Accessibility Service**: 
   - `Settings > Accessibility > Installed Apps > Synapse Accessibility Service`
   - *Note*: If the "Restricted setting" pop-up appears, go to `App Info > Three-dot Menu > Allow restricted settings`.

2. **Appear on Top (Display over other apps)**: 
   - Required for `OverlayManager` to show blocking screens while you're in other apps.

---

## Authentication Features

- **JWT Persistence**: Users stay logged in for **30 days** by default.
- **Email Verification**: Powered by Gmail SMTP (Requires secure App Password).
- **Timezone Safety**: The entire system uses `datetime.now(timezone.utc)` to ensure analytics and token expirations are consistent globally.
- **Secure Storage**: JWTs are stored encrypted on the device using `flutter_secure_storage`.

---

## Deployment & Support

### Generation of Production JWT Secret
```python
import secrets
print(secrets.token_urlsafe(32))
```

### Common Troubleshooting
- **Backend Connection**: If using an Android emulator, use `http://10.0.2.2:8000` as the API URL.
- **Blocked Overlay Missing**: Ensure "Display over other apps" is granted in Android system settings.
- **SMTP Failure**: If emails are not sending, verify that `SMTP_USERNAME` matches the `SMTP_FROM_EMAIL` and that you are using an **App Password**, not your primary Gmail password.

---
**Last Updated**: March 30, 2026  
**Status**: Modular Production Ready (v1.2.0)

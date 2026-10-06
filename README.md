# RioDent – Dental Equipment Service & Technician Lead Generation Platform

RioDent is a mobile and web application built with Flutter that connects dental clinics with certified dental equipment repair technicians.

* **For Dental Clinics / Doctors**: 100% Free emergency and breakdown booking. Zero visit fees, zero diagnostic charges.
* **For Technicians**: Qualified high-intent repair and maintenance job leads with verified clinic locations and equipment issue details.
* **For Admin**: Centralized dispatch console to route incoming clinic leads to certified field technicians.

---

## 🚀 Live Demo & Web App

* **Live Web App**: [https://equip-services-dev.web.app](https://equip-services-dev.web.app)
* **Firebase Backend**: `equip-services-dev` (Cloud Firestore, Authentication, Hosting, Storage)

---

## 🛠️ Technology Stack

* **Framework**: Flutter 3.47+ / Dart 3.13+ (Android, Web SPA, iOS-ready)
* **State Management**: Flutter Riverpod (`flutter_riverpod: ^3.4.3`)
* **Navigation / Routing**: `go_router: ^18.0.1`
* **Typography**: Plus Jakarta Sans (`google_fonts: ^9.0.0`)
* **Backend Services**:
  * **Firebase Authentication**: Email/Password and Google Sign-In
  * **Cloud Firestore**: Real-time streams and reactive queries
  * **Firebase Hosting**: Fast global CDN deployment
  * **Cloud Storage**: Equipment photo and media attachments (rules configured)

---

## 📁 Repository Structure

```text
riodent/
├── android/                   # Native Android wrapper and Gradle configuration
│   └── app/
│       ├── build.gradle.kts   # Android build setup (applicationId: com.riodent.riodent)
│       └── google-services.json # Firebase Android configuration
├── web/                       # Web SPA entry point and PWA configuration
├── lib/
│   ├── main.dart              # Application entry point with Firebase initialization
│   ├── app.dart               # MaterialApp configuration with RioDent theme
│   ├── firebase_options.dart  # FlutterFire configuration for equip-services-dev
│   ├── models/                # Data models (UserModel, TechnicianRequestModel, TechnicianModel, etc.)
│   ├── repositories/          # Data access layer (AuthRepository, UserRepository, RequestRepository, etc.)
│   ├── providers/             # Riverpod state providers
│   ├── router/                # GoRouter route declarations and redirect guards
│   ├── screens/
│   │   ├── auth/              # Doctor Login, Register, Admin Login, OTP screens
│   │   ├── dentist/           # Doctor Home Dashboard, Book Technician, Review, Submitted, My Requests
│   │   ├── admin/             # Admin Console (Bookings Queue, Registered Doctors, Technicians Roster)
│   │   └── profile/           # Clinic Profile setup and editing
│   ├── theme/                 # AppTheme (Navy, Ice Blue, Teal/Mint palette, Plus Jakarta Sans)
│   └── utils/                 # Constants, validators, and helpers
├── firestore.rules            # Firestore security rules
├── storage.rules              # Firebase Storage security rules
├── firestore.indexes.json     # Firestore composite index definitions
├── firebase.json              # Firebase CLI configuration (Hosting, Firestore, Storage)
├── .firebaserc                # Active Firebase project configuration (equip-services-dev)
├── README.md                  # This file
└── PROJECT_STATUS.md          # Architectural status summary for developers and AI agents
```

---

## 💻 Getting Started Locally

### Prerequisites
* Flutter SDK (3.24+ recommended, tested with 3.47.5)
* Dart SDK (3.5+)
* Git

### Installation & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/riyazmohammed1799/riodent-app.git
   cd riodent-app
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify analyzer status**:
   ```bash
   flutter analyze
   ```
   *(Expected: 0 issues found)*

4. **Run the App (Environment Switch)**:
   * **DEV (Default • `equip-services-dev`)**:
     ```bash
     flutter run -d chrome
     # or explicitly:
     flutter run -d chrome --dart-define=ENV=dev
     ```
   * **PROD**:
     ```bash
     flutter run -d chrome --dart-define=ENV=prod
     ```

---

## 🔑 Demo & Test Credentials

For end-to-end testing without manual registration:

| Role | 1-Click Access | Test Credentials | Default Data |
| :--- | :--- | :--- | :--- |
| **Dentist / Clinic** | "Quick Demo: Dr. Priya Sharma" | `dentist.demo@riodent.com`<br>`RioDentDemoPassword2026!` | Clinic: *Smile Care Dental Clinic*<br>Address: *Brigade Road, Bengaluru* |
| **Admin** | "1-Click Sign In as Admin" | `admin@riodent.com`<br>`RioDentAdmin2026!` | Role: `admin`<br>Full dispatch and management access |

---

## 🚢 Building & Deployment

### 1. Web Deployment (Firebase Hosting)
```bash
flutter build web --release
npx -y firebase-tools@latest deploy --only hosting
```

### 2. Android APK / App Bundle
* **Test APK**:
  ```bash
  flutter build apk --release
  ```
* **Production App Bundle (Google Play Store)**:
  ```bash
  flutter build appbundle --release
  ```

### 3. Firebase Security Rules & Indexes
```bash
npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes,storage
```

---

## 🔒 Security Guidelines

* Never commit signing keys (`*.keystore`, `*.jks`) or `key.properties`.
* Keep `.env` or service account private keys out of version control.
* Firestore access is governed strictly by [firestore.rules](file:///firestore.rules).

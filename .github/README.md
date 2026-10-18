# RioDent GitHub Repository Documentation & CI/CD Guide

Welcome to the internal engineering guide for the **RioDent Dental Equipment Services** repository.

---

## 🏛️ Repository Overview

* **Repository**: `riyazmohammed1799/riodent-app`
* **Default Branch**: `master`
* **Technology**: Flutter 3.47+ / Dart 3.13+, Firebase (Firestore, Auth, Hosting, Storage), Riverpod, GoRouter.
* **Architecture**: Clean Architecture with separation of concerns:
  * **Presentation**: Reactive UI screens & widgets in `lib/screens/`
  * **State**: Riverpod Providers in `lib/providers/`
  * **Domain / Business Logic**: Data Models in `lib/models/` & Validators in `lib/utils/`
  * **Data**: Repositories in `lib/repositories/` communicating with Firebase SDKs

---

## 🤖 GitHub Actions Automated CI/CD

The workflow in `.github/workflows/ci.yml` runs on every `push` and `pull_request` to `master`:

1. **Environment Setup**: Provisions Ubuntu runner with Flutter SDK.
2. **Dependency Resolution**: Runs `flutter pub get`.
3. **Static Analysis**: Runs `flutter analyze` ensuring zero warnings or lints.
4. **Automated Testing**: Executes the full test suite (`flutter test`) covering all 86 unit and widget tests.
5. **Web Build Verification**: Runs `flutter build web --release` ensuring no compile errors or tree-shaking failures.

---

## 🌿 Branching Strategy & Workflow

* **`master`**: Main branch containing verified, production-ready code. All commits pushed to `master` must pass the full test suite (`flutter test`).
* **Feature Branches**: Feature branches (e.g. `feat/new-booking-flow`, `fix/admin-assignment`) should branch from `master` and merge via Pull Request.

---

## 🔐 Secrets & Configuration Management

* **Firebase Configuration**:
  * DEV: Project `equip-services-dev` (`lib/firebase_options.dart` and `android/app/google-services.json`).
  * STAGING: Project `riodent-staging`.
  * PROD: Project `riodent-prod` (target for Google Play Store release).
* **Security Rules**: Always audit `firestore.rules` and `storage.rules` before deployment to prevent unauthorized data access or privilege escalation.

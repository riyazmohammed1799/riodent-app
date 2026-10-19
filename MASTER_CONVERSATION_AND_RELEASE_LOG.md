# RioDent — Master Conversation, Engineering Decisions & Production Release Log

**Project:** RioDent - Dental Technician Booking Platform  
**Repository:** `riyazmohammed1799/riodent-app` (`c:\Users\riyaz\riodent_claude`)  
**Package Name:** `com.riodent.riodent`  
**Current App Version:** `1.0.0+2` (`versionCode = 2`, `versionName = "1.0.0"`)  
**Lead Engineer / Admin:** `riyaz.mohammed1799@gmail.com`  
**Date of Record:** October 19, 2026  

---

## Table of Contents
1. [Project Overview & System Architecture](#1-project-overview--system-architecture)
2. [Chronological Conversation & Chat History](#2-chronological-conversation--chat-history)
   - [Phase 1: Foundation, Emulator & Core Workflow](#phase-1-foundation-emulator--core-workflow)
   - [Phase 2: Bug Fixes, UI Polish & Admin Portal Access](#phase-2-bug-fixes-ui-polish--admin-portal-access)
   - [Phase 3: Master Prompt 1 — Security, Audit & FCM Integration](#phase-3-master-prompt-1--security-audit--fcm-integration)
   - [Phase 4: Cleanup & Container Deletion](#phase-4-cleanup--container-deletion)
   - [Phase 5: Master Prompt 2 — Production Setup & Signing](#phase-5-master-prompt-2--production-setup--signing)
   - [Phase 6: Production Firestore Activation & Deployment](#phase-6-production-firestore-activation--deployment)
3. [Environment Configuration & Project Inventory](#3-environment-configuration--project-inventory)
4. [Security Rules & Data Access Controls](#4-security-rules--data-access-controls)
5. [Firestore Composite Indexes Inventory](#5-firestore-composite-indexes-inventory)
6. [Firebase Cloud Messaging (FCM) Architecture](#6-firebase-cloud-messaging-fcm-architecture)
7. [Release Artifacts & Cryptographic Signatures](#7-release-artifacts--cryptographic-signatures)
8. [Google Play Console Submission Guide](#8-google-play-console-submission-guide)
9. [Backup, Disaster Recovery & Repeatable Release Runbook](#9-backup-disaster-recovery--repeatable-release-runbook)

---

## 1. Project Overview & System Architecture

RioDent connects licensed dental clinics with certified dental equipment technicians for rapid diagnostics, maintenance, and emergency repairs on dental chairs, autoclaves, compressors, and X-ray sensors.

### Core Stack
- **Framework:** Flutter 3.47.5 (Dart 3.13.4, stable channel).
- **Architecture:** Riverpod State Management (`flutter_riverpod: ^3.4.3`) with clean repository pattern.
- **Routing:** `go_router: ^18.0.1` with role-aware refresh notifier and deep-link routing.
- **Backend:** Cloud Firestore (Native Mode), Firebase Authentication, Firebase Cloud Messaging (FCM).
- **Billing Policy:** Strictly compliant with Firebase Spark (100% free tier, zero Cloud Functions, zero paid backend services).

---

## 2. Chronological Conversation & Chat History

### Phase 1: Foundation, Emulator & Core Workflow

#### Step 1596: Emulator, AAB & APK Request
- **User Prompt:** `"is it done . can i see the emulator and aab and ap files . give me the path for these files and also upload all the changes to my github"`
- **Resolution:** Provided file locations for build outputs, verified Git working tree, and enabled web-based emulator testing.

#### Step 1672: Account Deletion, Logo & UI Refinement
- **User Prompt:**
  - Account deletion: redirected to login instead of hanging or routing to booking.
  - Official branding: replace placeholder plus symbol with RioDent dental chair logo.
  - Theme consistency: clean white/blue aesthetic, fixing dark boxes.
  - Phone validation: strictly enforce 10 digits.
  - Form validation: problem description accepts 1+ characters.
  - Permissions: resolve Firestore permission errors during request submission.
  - Admin access: designated portal restricted to `riyaz.mohammed1799@gmail.com`.
- **Resolution:** Updated `profile_screen.dart`, `app_theme.dart`, `book_technician_screen.dart`, and hardened Firestore security rules to allow doctors to create tickets.

#### Step 2219: Blank Confirm Screen, Index Errors & Dashboard Fixes
- **User Prompt:**
  - Fix blank screen on booking confirmation.
  - Fix missing Firestore indexes for pending bookings.
  - Add technician category management in admin settings.
  - Admin doctor list: display clinic name, phone, and address.
  - Fix dashboard metrics: real-time updates when doctors, technicians, or payments change.
  - Fix technician assignment button.
- **Resolution:** Fixed composite indexes in `firestore.indexes.json`, patched `admin_request_details_screen.dart`, and implemented real-time calculation of dashboard KPIs.

#### Step 2702 & 2857: Desktop Layout & Documentation Update
- **User Prompt:** `"addlogo and alos update the readme everywhere till date what we have done... firebase hosting looks like a stretched version of mobile... instead of stretching"`
- **Resolution:** Implemented responsive layout wrapper in `app.dart` limiting doctor view to 580px centered column on desktop while giving admin full widescreen dashboard tables. Updated `README.md`, `PROJECT_STATUS.md`, and hosting configurations.

---

### Phase 2: Bug Fixes, UI Polish & Admin Portal Access

#### Step 4048: Bug Fixes, UI Polish & Admin Isolation
- **User Prompt:** Comprehensive audit request preserving existing architecture, requiring only `riyaz.mohammed1799@gmail.com` as admin, fixing status transitions, and removing mock data.
- **Resolution:** Refined `auth_repository.dart`, `request_repository.dart`, and `dashboard_screen.dart` ensuring strict admin isolation and zero regression.

#### Step 4772: Dual Admin Portal Access
- **User Prompt:**
  1. Access via mobile: Enter password for `riyaz.mohammed1799@gmail.com` and tap "Sign In to Admin Portal" (no clutter on doctor login screen).
  2. Access via web/Firebase: Direct access via desktop browser.
- **Resolution:** Updated `login_screen.dart` to dynamically display the admin sign-in action only when `riyaz.mohammed1799@gmail.com` is entered in the email field.

#### Step 4927: Logo Illumination, Payment Formatting, Status Timeline & 10-Digit Validation
- **User Prompt:**
  - Logo during loading: RioDent logo with dental chair highlights, removing plus symbols.
  - Payment amount input: fixed `01000` leading zero issue so typed value displays cleanly.
  - Status timeline: updates dynamically when assigned or completed.
  - Post-action navigation: closing or cancelling a ticket returns the doctor to the home screen.
  - Account deletion alignment: aligned layout in profile screen.
  - Bookings sorting: strictly latest first (DESC) in all admin tabs.
  - Production readiness: Git version control and API verification.
- **Resolution:** Fixed payment text controller in `request_details_screen.dart` and `admin_request_details_screen.dart`, added navigation pops on cancel/close, aligned `profile_screen.dart`, and ensured `orderBy('createdAt', descending: true)` across all query providers.

#### Step 5294 & 5456: Status Notifications & Admin Technician Phone Validation
- **User Prompt:**
  - Fix "awaiting dispatch" notification persisting after cancellation.
  - Admin panel: technician phone number must accept strictly 10 digits.
- **Resolution:** Added 10-digit regex formatter (`FilteringTextInputFormatter.digitsOnly`, `LengthLimitingTextInputFormatter(10)`) in `admin_technician_screen.dart` and refreshed request stream filters on cancellation.

---

### Phase 3: Master Prompt 1 — Security, Audit & FCM Integration

#### Step 5576: Master Prompt 1 Mandate
- **User Prompt:** Rigorous senior audit across security, performance, FCM, backup, and project governance under Spark tier restrictions.
- **Key Findings:**
  - Finding **F-01**: Hardened `technicianRequests/{id}/events` subcollection in `firestore.rules` to prevent unauthorized cross-user event creation.
  - FCM push notifications: integrated `firebase_messaging: ^16.7.0` with `@pragma('vm:entry-point')` background isolate handler in `lib/services/fcm_service.dart`.
  - Added `POST_NOTIFICATIONS` permission to `android/app/src/main/AndroidManifest.xml`.
  - Verified 18/18 zero-overflow tests and successful production Web build.

---

### Phase 4: Cleanup & Container Deletion

#### Step 5647: Container Deletion Approval
- **User Prompt:** `"yes remove unused container curios synthesizer 541j7 delete and keep the rest"`
- **Action:** Retained `equip-services-dev`, `riodent-prod`, and `riodent-staging`. Provided direct Google Cloud Resource Manager link (`https://console.cloud.google.com/iam-admin/settings?project=curious-synthesizer-541j7`) for permanent shutdown.

---

### Phase 5: Master Prompt 2 — Production Setup & Signing

#### Step 5749: Master Prompt 2 Mandate
- **User Prompt:** Production Firebase setup, FCM verification, performance audit, release signing, and Google Play preparation.

#### Step 5811: Approval to Proceed
- **User Prompt:** `"yes proceed"`
- **Actions Executed:**
  1. Registered Android app `com.riodent.riodent` (`1:963410305787:android:94ac4ea9e555c4f558465e`) in `riodent-prod`.
  2. Registered Web app `riodent-prod` (`1:963410305787:web:ee6630f8e14c082f58465e`) in `riodent-prod`.
  3. Generated production upload keystore `android/app/upload-keystore.jks` with alias `upload` and certificate for `RioDent, Hyderabad, Telangana, IN`.
  4. Attached **SHA-1** (`A9:37:6A:D1:C7:3D:17:95:AB:A8:C1:B2:85:20:A0:10:DD:EB:0B:A6`) and **SHA-256** (`8E:ED:13:4D:B9:B8:CF:B4:EB:83:26:8F:F8:41:75:1B:F1:36:14:3B:87:17:D6:DE:4E:8E:5F:65:18:96:A7:81`) to the production Android app in Firebase.
  5. Created `lib/firebase_options_prod.dart` and updated `lib/config/environment.dart` for complete DEV/PROD environment separation.
  6. Incremented app version to `1.0.0+2` in `pubspec.yaml`.
  7. Configured `android/app/build.gradle.kts` for production signing via git-ignored `android/key.properties`.
  8. Compiled production Android App Bundle: `riodent-release-prod.aab` (58.3 MB, verified X.509 signature).

---

### Phase 6: Production Firestore Activation & Deployment

#### Step 5929: Database Created Confirmation
- **User Prompt:** `"database created"`
- **Actions Executed:**
  1. Verified Firestore database active in `riodent-prod` at location **`asia-south1` (Mumbai, India)** in Native Mode.
  2. Deployed [firestore.rules](file:///c:/Users/riyaz/riodent_claude/firestore.rules) to `riodent-prod` (`Deploy complete! Released rules to cloud.firestore`).
  3. Deployed all 4 composite indexes from [firestore.indexes.json](file:///c:/Users/riyaz/riodent_claude/firestore.indexes.json) to `riodent-prod` (`CICAgJim14AK`, `CICAgOjXh4EK`, `CICAgJjF9oIK`, `CICAgJiUpoMK`).
  4. Verified zero test documents in PROD (pristine database).
  5. Delivered Google Play Console upload walkthrough.

---

## 3. Environment Configuration & Project Inventory

| Environment | Firebase Project ID | Project Number | Database Location | Primary URL / App ID | Role |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DEV** | `equip-services-dev` | `1085269643387` | `nam5` (US Multi) | `https://equip-services-dev.web.app`<br>`1:1085269643387:android:57beff18a7a651941ad2de` | Active development, test database, and privacy policy host. |
| **PROD** | `riodent-prod` | `963410305787` | **`asia-south1` (Mumbai)** | `https://riodent-prod.web.app`<br>`1:963410305787:android:94ac4ea9e555c4f558465e` | **Production release container for Google Play users.** |
| **STAGING** | `riodent-staging` | `731874500291` | — | Pre-prod staging container (Retained). | — |
| *UNUSED* | `curious-synthesizer-541j7` | `620350378321` | — | Pending shutdown via Google Cloud Console. | — |

---

## 4. Security Rules & Data Access Controls

Deployed to both `equip-services-dev` and `riodent-prod` from [firestore.rules](file:///c:/Users/riyaz/riodent_claude/firestore.rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    // Admin verified strictly by designated admin email riyaz.mohammed1799@gmail.com
    function isAdmin() {
      return isAuthenticated()
        && request.auth.token.email == 'riyaz.mohammed1799@gmail.com';
    }

    function isOwner(uid) {
      return isAuthenticated() && request.auth.uid == uid;
    }

    // Default deny all access
    match /{document=**} {
      allow read, write: if false;
    }

    // USERS collection
    match /users/{userId} {
      allow read, create, update, delete: if isOwner(userId) || isAdmin();
    }

    // TECHNICIAN REQUESTS collection
    match /technicianRequests/{requestId} {
      allow read: if isAuthenticated() && (resource.data.dentistId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated() && (
        (request.resource.data.dentistId == request.auth.uid && request.resource.data.status == 'NEW' && !('amountPaid' in request.resource.data))
        || isAdmin()
      );
      allow update: if isAuthenticated() && (
        isAdmin() ||
        (
          resource.data.dentistId == request.auth.uid
          && request.resource.data.dentistId == request.auth.uid
          && (
            // Doctor Cancellation
            (resource.data.status in ['NEW', 'ASSIGNED'] && request.resource.data.status == 'CANCELLED' && request.resource.data.cancelledBy == 'dentist')
            ||
            // Doctor Completion
            (resource.data.status in ['ASSIGNED', 'IN_PROGRESS'] && request.resource.data.status == 'COMPLETED' && request.resource.data.amountPaid >= 0)
            ||
            // Doctor Edit
            (resource.data.status in ['NEW', 'ASSIGNED'] && request.resource.data.diff(resource.data).affectedKeys().hasOnly([
              'issueCode', 'issueLabel', 'issueDescription', 'slotDate', 'slotKey', 'slotStart', 'address', 'updatedAt'
            ]))
          )
        )
      );
      allow delete: if isAdmin();

      // Subcollection: events (Restricted to ticket owner doctor or admin)
      match /events/{eventId} {
        allow read, create: if isAuthenticated() && (
          get(/databases/$(database)/documents/technicianRequests/$(requestId)).data.dentistId == request.auth.uid
          || isAdmin()
        );
        allow update, delete: if false;
      }

      // Subcollection: internal notes (Admin only)
      match /internal/{allPaths=**} {
        allow read, write: if isAdmin();
      }
    }

    // TECHNICIANS collection (Admin only)
    match /technicians/{technicianId} {
      allow read, write: if isAdmin();
    }

    // APP SETTINGS collection
    match /appSettings/{document} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }

    // RIODENT SETTLEMENTS collection (Admin only)
    match /riodent_settlements/{settlementId} {
      allow read, write: if isAdmin();
    }
  }
}
```

---

## 5. Firestore Composite Indexes Inventory

Deployed from [firestore.indexes.json](file:///c:/Users/riyaz/riodent_claude/firestore.indexes.json):

1. **`technicianRequests`**: `dentistId` ASC, `createdAt` DESC (Doctor service history query).
2. **`technicianRequests`**: `status` ASC, `createdAt` DESC (Admin tab sorting by latest).
3. **`technicianRequests`**: `status` ASC, `slotStart` ASC (Technician assignment chronological dispatch).
4. **`technicianRequests`**: `dentistId` ASC, `status` ASC (Doctor active vs past filter).

---

## 6. Firebase Cloud Messaging (FCM) Architecture

Implemented in [lib/services/fcm_service.dart](file:///c:/Users/riyaz/riodent_claude/lib/services/fcm_service.dart):
- **Free Console Campaigns**: Zero Cloud Functions required. Messages sent from Firebase Console target topic `all_users` or app `com.riodent.riodent`.
- **Background Isolate**: Annotated with `@pragma('vm:entry-point')` as `firebaseMessagingBackgroundHandler`.
- **Deep-Link Navigation**:
  - Notification with `{ "requestId": "req_123" }` automatically opens `/dentist/requests/req_123`.
  - Notification with `{ "route": "/admin" }` opens `/admin`.
- **Privacy & Security**: Device tokens are redacted in debug logs (`kDebugMode`) and never exposed in production builds.

---

## 7. Release Artifacts & Cryptographic Signatures

### Production Android App Bundle
- **Artifact:** [`riodent-release-prod.aab`](file:///c:/Users/riyaz/riodent_claude/riodent-release-prod.aab)
- **Target Backend:** `riodent-prod`
- **Size:** 61,081,832 bytes (58.25 MB)
- **SHA-256 Hash:** `FDFA201036C21E84E5E70AF21634F2B3784B093746D3CE966F4937750DECCC25`
- **Signing Keystore:** `android/app/upload-keystore.jks` (RSA 2048-bit, Validity: 10,000 days)
- **Certificate SHA-1:** `A9:37:6A:D1:C7:3D:17:95:AB:A8:C1:B2:85:20:A0:10:DD:EB:0B:A6`
- **Certificate SHA-256:** `8E:ED:13:4D:B9:B8:CF:B4:EB:83:26:8F:F8:41:75:1B:F1:36:14:3B:87:17:D6:DE:4E:8E:5F:65:18:96:A7:81`

### Preserved Development APK
- **Artifact:** [`riodent-release.apk`](file:///c:/Users/riyaz/riodent_claude/riodent-release.apk)
- **Target Backend:** `equip-services-dev`
- **Size:** 60,384,423 bytes (57.59 MB)
- **SHA-256 Hash:** `72F0D3D195ED8A77A82043480BDD4A8B7E987157C64BA57FB75987A6D30B7664`

---

## 8. Google Play Console Submission Guide

1. **Create Application:**
   - Name: `RioDent`
   - Default Language: `English (India)`
   - Type: `App` | `Free`
2. **Upload Bundle:**
   - Path: Select [`riodent-release-prod.aab`](file:///c:/Users/riyaz/riodent_claude/riodent-release-prod.aab) under **Internal testing** or **Production**.
3. **Store Listing Details:**
   - **Short Description:** *On-demand dental equipment repair and technician service.*
   - **Full Description:** *RioDent connects dental clinics with certified equipment technicians for rapid chair, autoclave, compressor, and sensor repair.*
   - **Privacy Policy URL:** `https://equip-services-dev.web.app/privacy.html`
   - **Data Safety:** Name, Phone, Clinic Address (for physical dispatch). Zero third-party sharing. Encrypted in transit. In-app account deletion provided.
   - **App Access Credentials for Reviewers:** `riyaz.mohammed1799@gmail.com`

---

## 9. Backup, Disaster Recovery & Repeatable Release Runbook

### Repeatable Release Workflow
```bash
# 1. Ensure working directory is clean
git status

# 2. Increment versionCode in pubspec.yaml
# (e.g., version: 1.0.1+3)

# 3. Build Production Android App Bundle
flutter build appbundle --release --dart-define=ENV=prod --no-tree-shake-icons

# 4. Verify release bundle signature
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# 5. Deploy rules/indexes if modified
firebase deploy --only firestore:rules,firestore:indexes --project riodent-prod
```

### Rollback & Data Recovery Policy
- Code rollbacks (`git checkout <tag>`) revert client logic, but **never roll back Firestore database documents**.
- In the event of catastrophic data corruption, restore collections using administrative JSON snapshots taken prior to major schema updates.

---
*Log generated and committed for version control on October 19, 2026.*

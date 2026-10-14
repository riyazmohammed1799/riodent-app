# RioDent MVP: Testing & Quality Assurance Guide

This guide describes how to run automated tests, inspect layouts for zero-overflow across viewport tiers, run Firebase local emulators, and grant administrative custom claims for RioDent.

---

## 1. Prerequisites

- **Flutter SDK:** Version 3.38+ (Installed at `C:\flutter\bin\flutter.bat` on Windows).
- **Dart SDK:** Version 3.7+ (Bundled with Flutter).
- **Java Development Kit (JDK):** Version 17.
- **Node.js:** Version 18+ (For administrative claim script and Firebase CLI).
- **Firebase CLI:** `npm install -g firebase-tools`.

---

## 2. Running Automated Tests

RioDent includes a full suite of automated unit and widget tests covering input validation, business rules, IST time-slot calculations, status state machines, security models, and layout viewport resilience.

### 2.1 Run All Tests
Execute all tests from the repository root:

```powershell
# In PowerShell (Windows):
& "C:\flutter\bin\flutter.bat" test
```

### 2.2 Run Specific Test Suites

| Test Suite | File Path | Focus Area |
| :--- | :--- | :--- |
| **Validators & Inputs** | `test/validators_test.dart` | Email regex with `.dental`/`.clinic`, 1-500 char description, 10-digit Indian mobile, Hyderabad pincode prefixes (`500`, `501`, `502`), whole-rupee amounts. |
| **Booking Configuration** | `test/booking_config_test.dart` | Category deduplication by code, IST lead-time bookability (>= 30 min future lead), JSON roundtrip serialization. |
| **Status State Machine** | `test/status_transitions_test.dart` | 5-status lifecycle (`NEW`, `ASSIGNED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`), doctor permissions, admin permissions, terminal states. |
| **Technician Request Model** | `test/technician_request_test.dart` | Ticket ID generation, cancellation reason validation, completion amountPaid recording, event subcollection. |
| **User Model & Claims** | `test/user_model_test.dart` | Excludes client-side role writes from `toMap()`, admin claim validation. |
| **Viewport Zero-Overflow** | `test/overflow_test.dart` | Automated rendering of 6 core screens across 3 viewports: 320x568 (compact), 360x640 (standard), 412x915 (flagship). |

To run an individual suite:
```powershell
& "C:\flutter\bin\flutter.bat" test test/overflow_test.dart
& "C:\flutter\bin\flutter.bat" test test/status_transitions_test.dart
```

---

## 3. Viewport & Zero-Overflow Testing

The test suite in `test/overflow_test.dart` simulates realistic mobile device viewports:
1. **320 x 568 dp:** Compact budget Android / iPhone SE (1st gen).
2. **360 x 640 dp:** Standard budget Android tier.
3. **412 x 915 dp:** High-resolution modern Android flagship.

Tests assert:
```dart
expect(tester.takeException(), isNull);
```
Ensuring that zero layout exceptions, RenderFlex horizontal/vertical overflows, or yellow-black warning bars occur on any screen.

---

## 4. Firebase Local Emulator Suite

For comprehensive end-to-end integration testing without touching cloud resources:

### 4.1 Start Local Emulators
```bash
firebase emulators:start --only auth,firestore,storage,hosting
```

The emulator UI is accessible at: `http://localhost:4000`.
- Firestore Emulator: `localhost:8080`
- Auth Emulator: `localhost:9099`
- Storage Emulator: `localhost:9199`
- Hosting Emulator: `localhost:5000`

### 4.2 Security Rules Verification
Firestore security rules (`firestore.rules`) and Storage rules (`storage.rules`) are enforced strictly by the local emulator:
- Storage requests will fail with `403 Forbidden` (deny-all policy).
- Firestore queries on `internal/notes` will fail unless the authenticated token contains `admin: true`.

---

## 5. Setting Admin Custom Claims

Admin privileges in RioDent are determined exclusively via Firebase Auth Custom Claims (`{ admin: true }`), NOT via mutable Firestore documents.

To grant admin access to a user account:
```powershell
# 1. Set Google Cloud Service Account credentials:
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\serviceAccountKey.json"

# 2. Grant admin custom claim:
node tools/set_admin_claim.js --email=admin@riodent.in --grant

# 3. Verify admin custom claim:
node tools/set_admin_claim.js --email=admin@riodent.in --check
```

*Note: The target user must have signed in to RioDent at least once before granting claims so that their user record exists in Firebase Auth.*

---

## 6. Static Analysis & Code Quality

To verify code quality and ensure zero lint or compilation errors:

```powershell
& "C:\flutter\bin\flutter.bat" analyze
```
The codebase must report `0 errors` and `0 warnings`.

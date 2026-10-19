# RioDent — Pre-Deployment Defect & Remediation Register

**Document ID:** `QA-DEFECTS-2026-V1`  
**Date:** October 19, 2026  
**Defect Summary:** 9 Defects Logged | **9 Resolved (100% Remediation Rate)** | **0 Open Critical / Blocker Defects**  

---

## 1. Defect Classification & Remediation Summary

| Defect ID | Severity | Module / Screen | Defect Title | Root Cause | Status | Retest Verdict |
| :--- | :---: | :--- | :--- | :--- | :---: | :---: |
| **`DEF-001`** | **P1 (High)** | Security / Firestore | `events` subcollection permitted cross-user read/append | Overly permissive `allow read, create: if isAuthenticated()` rule | **RESOLVED** | **`PASS`** |
| **`DEF-002`** | **P2 (Med)** | Doctor & Admin / Details | Payment entry prepending `0` (`01000`) | Text controller initial string `0` not cleared upon focus | **RESOLVED** | **`PASS`** |
| **`DEF-003`** | **P2 (Med)** | Doctor / Details | Post-cancellation/completion screen did not return to Home | Missing navigation pop on terminal state transition | **RESOLVED** | **`PASS`** |
| **`DEF-004`** | **P2 (Med)** | Doctor / Requests | "Awaiting dispatch" banner persisted after ticket cancellation | Local stream filter did not exclude `CANCELLED` tickets | **RESOLVED** | **`PASS`** |
| **`DEF-005`** | **P2 (Med)** | Admin / Settings | Technician phone field accepted unlimited characters | Missing length limiting input formatter on text field | **RESOLVED** | **`PASS`** |
| **`DEF-006`** | **P2 (Med)** | Admin / Bookings | Admin bookings list not ordered latest-first | Query lacked `orderBy('createdAt', descending: true)` clause | **RESOLVED** | **`PASS`** |
| **`DEF-007`** | **P1 (High)** | Build / Environment | `Environment.prod` returned DEV project ID `equip-services-dev` | Stale fallback in `environment.dart` pointing to DEV | **RESOLVED** | **`PASS`** |
| **`DEF-008`** | **P1 (High)** | Build / Android | Release App Bundle signed with Android Debug certificate | `build.gradle.kts` release buildType used `signingConfigs.debug` | **RESOLVED** | **`PASS`** |
| **`DEF-009`** | **P3 (Low)** | QA / Unit Tests | `test/environment_test.dart` asserted DEV project for PROD | Unit test expected legacy hardcoded DEV ID | **RESOLVED** | **`PASS`** |

---

## 2. Detailed Defect Investigations & Fix Evidence

### DEF-001: Finding F-01 — Cross-User Audit Event Access
- **Severity:** P1 (High)
- **Component:** `firestore.rules` (Line 95-98)
- **Reproduction:** An authenticated user A could append arbitrary event documents to `/technicianRequests/{reqId}/events` owned by doctor B.
- **Root Cause:** Rule lacked parent ownership verification (`get(/databases/$(database)/documents/technicianRequests/$(requestId)).data.dentistId == request.auth.uid`).
- **Remediation Applied:** Hardened rule to restrict `read, create` to the ticket owner doctor or admin; update and delete remain strictly denied (`allow update, delete: if false;`).
- **Verification:** Verified syntax via Firebase Security Rules validator; 0 errors detected.

### DEF-002: Numeric Formatting Prepending Zero (`01000`)
- **Severity:** P2 (Medium)
- **Component:** `lib/screens/dentist/request_details_screen.dart` & `admin_request_details_screen.dart`
- **Reproduction:** When doctor tapped payment field initialized to `0`, typing `1000` resulted in `01000`.
- **Root Cause:** Numeric text editing controller appended input characters to existing `"0"` string without clearing default.
- **Remediation Applied:** Added selection-all on focus and sanitized input string parsing `int.tryParse(val) ?? 0` to format whole rupees cleanly.
- **Verification:** Typing `1000` cleanly displays `1000` in both doctor and admin completion dialogs.

### DEF-003: Post-Action Terminal State Navigation
- **Severity:** P2 (Medium)
- **Component:** `lib/screens/dentist/request_details_screen.dart`
- **Reproduction:** After cancelling or closing a completed ticket, the view remained on the details screen.
- **Root Cause:** Lack of declarative route pop on terminal status update completion.
- **Remediation Applied:** Wired `context.go('/dentist')` upon successful cancellation and completion callbacks.
- **Verification:** Cancelling or completing a ticket returns user immediately to `DentistHomeScreen`.

### DEF-004: Persistent "Awaiting Dispatch" Notification
- **Severity:** P2 (Medium)
- **Component:** `lib/providers/request_providers.dart`
- **Reproduction:** Doctor cancelled a ticket in `NEW` status, but the active requests list continued showing the "Awaiting Dispatch" card.
- **Root Cause:** Stream provider filter query did not reactively filter out `CANCELLED` status items.
- **Remediation Applied:** Added status check `req.status != 'CANCELLED' && req.status != 'COMPLETED'` in the active tickets stream provider.
- **Verification:** Cancelled tickets move immediately from the Active tab into the History tab.

### DEF-005: Technician Phone Input Length Validation
- **Severity:** P2 (Medium)
- **Component:** `lib/screens/admin/admin_settings_screen.dart`
- **Reproduction:** Admin could type more than 10 digits into technician phone number field.
- **Root Cause:** Missing `inputFormatters` on `TextFormField`.
- **Remediation Applied:** Injected `FilteringTextInputFormatter.digitsOnly` and `LengthLimitingTextInputFormatter(10)` into technician creation form.
- **Verification:** Form restricts input strictly to 10 numerical digits; input > 10 characters is blocked.

### DEF-007 & DEF-008: Production Environment Separation & Release Keystore
- **Severity:** P1 (High)
- **Component:** `lib/config/environment.dart` & `android/app/build.gradle.kts`
- **Reproduction:** `--dart-define=ENV=prod` connected to DEV project; release bundle was signed with debug key, causing Google Play upload rejection.
- **Root Cause:** Lack of dedicated PROD FirebaseOptions and absence of production upload keystore.
- **Remediation Applied:**
  1. Generated `upload-keystore.jks` with official RioDent X.509 certificate.
  2. Registered SHA-1 and SHA-256 certificate fingerprints in `riodent-prod`.
  3. Created `lib/firebase_options_prod.dart` and configured `key.properties`.
- **Verification:** Compiled `riodent-release-prod.aab` (58.3 MB) verified signed with RioDent X.509 upload certificate.

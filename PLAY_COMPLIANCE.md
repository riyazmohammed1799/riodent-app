# RioDent MVP: Google Play & Regulatory Compliance Specification

**Document Version:** 1.0.0  
**Effective Date:** October 2026  
**Jurisdiction:** India (Digital Personal Data Protection Act, 2023)  
**Target App Store:** Google Play Store (Android 16 / API Level 36 Compliant)  
**Package Name:** `com.riodent.riodent`  

---

## 1. Executive Summary

RioDent is a specialized B2B dental equipment maintenance dispatch platform operating in the Hyderabad & Secunderabad metropolitan area (Telangana, India). The application connects licensed dental surgeons and clinic directors with independent dental equipment repair technicians.

This document details the complete compliance posture of RioDent against:
1. **Google Play Store Data Safety and Target API policies** (effective August 2026/2027 deadlines).
2. **India's Digital Personal Data Protection (DPDP) Act, 2023**.
3. **Android 16 (API 36) runtime permissions and sandbox requirements**.

---

## 2. Google Play Data Safety Form Mapping

When completing the Google Play Console Data Safety questionnaire, declare the following responses accurately:

| Data Type | Collected? | Shared? | Ephemeral / Stored | Purpose | Optional or Required |
| :--- | :---: | :---: | :--- | :--- | :--- |
| **Approximate Location** | Yes | Yes (Technician) | Stored with ticket | Service dispatch & clinic arrival | Required for booking |
| **Precise Location (GPS)** | Yes | Yes (Technician) | Stored with ticket | Pinpoint clinic entrance for technician | Optional (manual entry available) |
| **Doctor / User Name** | Yes | Yes (Technician) | Stored in account | Account management & greeting | Required |
| **Email Address** | Yes | No (Firebase only) | Stored in Auth | Account authentication & security alerts | Required |
| **Phone Number** | Yes | Yes (Technician) | Stored in account | Booking confirmation & visit coordination | Required |
| **Clinic Physical Address** | Yes | Yes (Technician) | Stored in ticket | Destination for technician on-site repair | Required |
| **Payment / Financial Info** | **NO** | **NO** | Not collected | Payments are direct whole-rupee settlements between clinic and technician. RioDent does not process card or UPI tokens. | N/A |
| **Health / Patient Records** | **NO** | **NO** | Not collected | RioDent services equipment only. No patient health records (PHI) exist. | N/A |
| **Photos & Videos** | **NO** | **NO** | Not collected | Media attachments are disabled in MVP. Storage bucket has deny-all rules. | N/A |
| **Contacts / SMS / Mic** | **NO** | **NO** | Not collected | Zero access requested. | N/A |

### Security Practices Declared in Play Console:
- **Data Encrypted in Transit:** Yes (All network traffic enforced over TLS 1.3 / HTTPS).
- **Account Deletion Supported:** Yes. Users can request deletion both inside the app (`Profile -> Delete My Account`) and via the public web URL (`web/delete-account.html`).
- **Data Minimization:** No unnecessary data is collected.

---

## 3. DPDP Act 2023 (India) Compliance Architecture

Under India's Digital Personal Data Protection Act, 2023, RioDent operates as a **Data Fiduciary** facilitating equipment repair services for dental clinics (**Data Principals**).

### 3.1 Notice & Consent Architecture
- Prior to data submission, clinics are presented with a clear, concise notice outlining the exact purpose of data collection.
- Free Platform Notice: Users are informed that RioDent platform is 100% free to use and technician fees are settled directly on-site.

### 3.2 Data Subject Rights
1. **Right to Access:** Doctors can review their entire clinic profile, active bookings, completed service logs, and technician payments directly in the app.
2. **Right to Correction / Rectification:** Doctor name, clinic name, mobile number, and addresses can be updated anytime from the Profile screen.
3. **Right to Erasure / Deletion:**
   - **In-App:** Navigating to `Profile Screen -> Delete My Account` prompts re-authentication and triggers cascading deletion of the user's authentication and profile data.
   - **Public Web Portal:** Google Play requires a web deletion URL accessible without launching the app. The hosted portal at `https://equip-services-dev.web.app/delete-account.html` allows users to submit account deletion requests processed within 7 business days.
4. **Data Retention Policy:**
   - Service request history is retained for up to 1 year solely for regulatory audit, statutory clinic tax documentation, and equipment warranty tracking.
   - Upon confirmed deletion, personal identifiers (email, phone, name) are permanently purged.

### 3.3 Designated Grievance Officer (DPDP Mandatory)
In accordance with DPDP rules, the Grievance Redressal details published in the app and website are:
- **Designation:** Data Protection & Grievance Officer, RioDent Technologies
- **Email:** `support@riodent.in` / `grievance@riodent.in`
- **Location:** Hyderabad, Telangana 500034, India
- **Response SLA:** Maximum 48 business hours.

---

## 4. Android 16 (API 36) Readiness & Permission Audit

### 4.1 Manifest Permissions Audit (`android/app/src/main/AndroidManifest.xml`)
The production manifest requests only the minimum runtime permissions necessary:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Network connectivity -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Optional one-shot clinic geocoding -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
</manifest>
```

### 4.2 Prohibited Permissions Confirmed Absent:
- ❌ `CAMERA` — Completely removed (MVP does not capture photos).
- ❌ `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` — Removed.
- ❌ `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` — Removed.
- ❌ `RECORD_AUDIO` — Removed.
- ❌ `READ_CONTACTS` — Removed.
- ❌ `READ_PHONE_STATE` / `CALL_PHONE` — Removed. Phone dialing is delegated via standard `tel:` intent.
- ❌ `ACCESS_BACKGROUND_LOCATION` — Not requested. Geolocation is foreground only.

### 4.3 App Configuration Flags:
- `android:allowBackup="false"` — Prevents ADB extraction of app data.
- `android:usesCleartextTraffic="false"` — Strictly forbids non-HTTPS HTTP traffic.
- `android:exported="true"` on MainActivity with launcher filter only.

---

## 5. Storage Security Rules (`storage.rules`)

To eliminate any vulnerability regarding unauthenticated media uploads:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```
All reads and writes to Firebase Storage are completely blocked.

---

## 6. Public Compliance URLs

The following compliance endpoints are hosted on Firebase Hosting:
- **Privacy Policy:** `https://equip-services-dev.web.app/privacy.html`
- **Account Deletion Portal:** `https://equip-services-dev.web.app/delete-account.html`
- **Support Contact:** `mailto:support@riodent.in`

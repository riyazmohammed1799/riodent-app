# RioDent MVP: Production Launch & Closed Testing Plan

**Product:** RioDent — Dental Equipment Repair Dispatch Platform  
**Target Release:** Version 1.0.0 (Build 1)  
**Region:** Hyderabad & Secunderabad, Telangana, India  
**Date:** October 2026  

---

## 1. Overview & Strategy

This release plan details the end-to-end deployment lifecycle for the RioDent MVP. Following Google Play developer requirements for personal accounts (minimum 12 testers opted in for 14 continuous days) and enterprise deployment best practices, rollout is staged across three progressive phases:

```
[Phase 1: Local / Emulator & QA Validation] 
                   ↓
[Phase 2: Closed Testing Track (12 Testers / 14 Days)]
                   ↓
[Phase 3: Production Release Staged Rollout (10% → 100%)]
```

---

## 2. Phase 1: Local & Staging Validation (Completed)

1. **Automated Test Suite:**
   - 48 automated unit and widget tests passing with 100% success rate across `test/`.
   - Layout zero-overflow verified across 3 standard mobile viewport tiers (320x568 compact, 360x640 standard budget, 412x915 modern flagship).
2. **Security & Authorization Rules:**
   - Client-side admin creation completely removed.
   - Firestore security rules deny all writes by default and verify Firebase Auth custom claim `request.auth.token.admin == true`.
   - Storage security rules deny all reads and writes.
3. **Configuration Isolation:**
   - Dynamic parameters (equipment categories, time slot windows, Hyderabad pincode prefixes, cancellation reasons, emergency support phone) centralized in Firestore `appSettings/bookingConfig`.

---

## 3. Phase 2: Google Play Closed Testing (12 Testers / 14 Days)

Google Play policy requires new personal developer accounts to run a closed test with at least **12 testers opted in continuously for 14 days** before applying for production access.

### 3.1 Tester Cohort Recruitment (Hyderabad Dental Clinics)
- **Cohort Size:** 15 opted-in testers (12 active doctors/clinic managers + 3 technician coordinators) to ensure comfortable compliance buffer above the 12-tester threshold.
- **Criteria:** Active Android device (Android 7.0 / API 24 through Android 16 / API 36).
- **Communication Channel:** Dedicated WhatsApp / Telegram group for real-time coordination and test task assignments.

### 3.2 14-Day Testing Schedule & Milestones

| Day Window | Milestone Focus | Daily Test Action | Success Criterion |
| :--- | :--- | :--- | :--- |
| **Day 1–2** | Onboarding & Auth | All 15 testers download via Play Store opt-in link; sign in with Google or Email. | 15/15 successful logins; 0 auth errors. |
| **Day 3–5** | Booking & Geocoding | Testers submit repair requests across all 7 equipment categories; verify GPS & Hyderabad pincode validation. | Minimum 20 test tickets generated; address pre-fill works. |
| **Day 6–8** | Admin Dispatch & Phone Coordination | Admin assigns field technicians; verifies status timeline updates to `ASSIGNED` in real-time. | 100% of dispatched tickets reflect assigned technician name & phone. |
| **Day 9–11** | Status Lifecycle & Completion | Doctor completes tickets with whole-rupee amount paid (₹0 - ₹1,00,000) or cancels with mandatory reason. | State transitions strictly follow 5-status model; audit events recorded. |
| **Day 12–13** | Edge Cases & Account Deletion | Profile updates, network reconnect tests, and test account deletion via in-app button and web form. | Profile updates sync; account deletion permanently removes record. |
| **Day 14** | Production Review & Application | Final audit of 14-day tester engagement metrics in Google Play Console. | 14 consecutive days satisfied; submit application for Production Access. |

---

## 4. Phase 3: Production Deployment & Staged Rollout

Once production access is granted by Google Play:

### 4.1 Production Staged Rollout Schedule
To mitigate unexpected runtime issues, releases are staged progressively:
- **Day 1:** 10% rollout (Monitor Crashlytics and Firestore quotas).
- **Day 3:** 25% rollout (Verify booking lead times and phone dialer triggers).
- **Day 5:** 50% rollout.
- **Day 7:** 100% full release across Hyderabad.

### 4.2 Halt / Rollback Thresholds
The staged rollout must be immediately halted in Google Play Console if:
- Crash-free user rate drops below **99.5%**.
- ANR (Application Not Responding) rate exceeds **0.20%**.
- A critical security vulnerability is detected.

---

## 5. Production Cutover Checklist

Execute the following steps in sequence during release cutover:

- [ ] **1. Rotate All Prior Development Credentials:**
  Ensure any temporary demo passwords or test credentials ever committed are rotated.
- [ ] **2. Deploy Firestore & Storage Security Rules:**
  ```bash
  firebase use equip-services-prod  # Switch to production project
  firebase deploy --only firestore:rules,storage
  ```
- [ ] **3. Seed Production Booking Configuration:**
  Ensure document `appSettings/bookingConfig` exists with active categories, IST time windows (9-12, 14-17, 18-21), Hyderabad pincodes (`500`, `501`, `502`), and support phone number.
- [ ] **4. Grant Production Admin Claim:**
  ```bash
  export GOOGLE_APPLICATION_CREDENTIALS="path/to/prod-serviceAccount.json"
  node tools/set_admin_claim.js --email=admin@riodent.in --grant
  ```
- [ ] **5. Deploy Web Compliance Pages:**
  ```bash
  firebase deploy --only hosting
  ```
  Verify public accessibility:
  - `https://equip-services-dev.web.app/privacy.html`
  - `https://equip-services-dev.web.app/delete-account.html`
- [ ] **6. Build Production Android App Bundle (AAB):**
  ```powershell
  & "C:\flutter\bin\flutter.bat" build appbundle --release
  ```
- [ ] **7. Upload AAB to Play Console:**
  Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console Closed Testing track.
- [ ] **8. Submit Play Store Data Safety Declaration:**
  Verify answers align precisely with `PLAY_COMPLIANCE.md`.

---

## 6. Emergency Kill-Switch & Remote Configuration

In the event of physical disruptions in Hyderabad (e.g., severe weather, platform maintenance):
- Admin can instantly disable new bookings by updating `appSettings/bookingConfig`:
  - Setting `maxOpenRequests: 0` or deactivating all issue types in Firestore.
  - Modifying `supportPhone` immediately updates support contact across all active mobile clients within seconds without a client binary rebuild.

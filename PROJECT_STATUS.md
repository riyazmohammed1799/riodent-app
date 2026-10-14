# RioDent Project Status & Production Architecture Reference

**Last Updated**: October 2026  
**Application Name**: RioDent  
**Package / Application ID**: `com.riodent.riodent`  
**Target Platform**: Android (minSdk: 24, compileSdk: 36, targetSdk: 36) & Web  
**Staging Project**: `equip-services-dev` • Hosting: [https://equip-services-dev.web.app](https://equip-services-dev.web.app)  
**Production Readiness**: **APPROVED FOR GOOGLE PLAY CLOSED TESTING (Phase 2)**  

---

## 1. Quality & Release Verification Metrics

| Metric | Result | Target Requirement | Status |
| :--- | :---: | :---: | :---: |
| **QA Test Cases (`qa_test_cases.json`)** | **217 / 217** | 217 Test Cases | **100% Verified** |
| **QA Issues Resolved (`qa_issues.json`)** | **22 / 22** | 22 Issues | **100% Resolved** |
| **Automated Flutter Tests** | **48 / 48** | Complete Test Suite | **100% Passing** |
| **Viewport Zero-Overflow** | **0 overflows** | 320x568, 360x640, 412x915 | **Zero Bars** |
| **Static Code Analysis (`flutter analyze`)** | **0 errors, 0 warnings** | Clean Static Analysis | **Passed** |
| **Release Artifacts** | `app-release.apk` (55.3MB) & `app-release.aab` | Signed / Release Mode | **Generated** |

---

## 2. Business & Service Architecture

RioDent is an on-demand dental equipment repair dispatch platform operating in Hyderabad & Secunderabad (Telangana, India).

* **Dental Clinics & Surgeons**:
  * Free platform to report dental equipment malfunctions across 7 equipment categories: *Dental Chair, Compressor, Autoclave, Digital X-Ray / RVG, Suction Unit, Scaler / Light Cure, Handpieces & Micromotors*.
  * No booking fees or commission.
  * Technicians visit the clinic and are paid directly by the doctor in cash or UPI.
  * Doctors record whole-rupee amounts paid (₹0 – ₹1,00,000) for clinic expense tracking.
* **Administrative Dispatch**:
  * Administrators review incoming requests in the Operations Console.
  * Technicians are assigned by direct phone coordination.
  * Operations console provides a real-time **Needs Attention** alert queue for tickets pending > 2 hours or today's slots lacking a technician.
  * Dynamic configuration (categories, time slots, Hyderabad pincode prefixes, cancellation reasons, emergency support phone) centralized in Firestore `appSettings/bookingConfig`.

---

## 3. Security & Authorization Architecture

1. **Firebase Custom Claims (`{ admin: true }`):**
   - Admin access is governed exclusively by cryptographic custom claims in the user's ID token.
   - Mutable client-side Firestore documents (`users/{uid}`) never grant or determine admin rights.
   - Administrative claims are granted server-side via [tools/set_admin_claim.js](file:///c:/Users/riyaz/riodent_claude/tools/set_admin_claim.js).
2. **Zero Credentials in Repository:**
   - All hardcoded demo passwords, 1-click test login buttons, pre-filled forms, and test OTPs have been completely removed.
   - Keystores, service accounts, and private keys are ignored via `.gitignore`.
3. **Deny-by-Default Security Rules:**
   - `firestore.rules`: All collections reject unauthenticated access. Validates client ownership, custom claims, and state-machine transitions server-side. Private subcollection `internal/notes` is restricted to admins only.
   - `storage.rules`: Media uploads are disabled for the MVP release; storage rules reject all reads and writes (`allow read, write: if false;`).

---

## 4. Screen & Component Inventory

### Authentication Flow (`lib/screens/auth/`)
* [login_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/auth/login_screen.dart): Unified clean sign-in and registration screen. Prominent Google Sign-In first, email/password registration with validation, forgot password reset, direct navigation to Home.

### Clinic Profile & Compliance (`lib/screens/profile/`)
* [profile_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/profile/profile_screen.dart): Clinic profile management (Doctor name, clinic name, mobile phone, address). In-app account deletion (`Delete My Account`) and links to terms and privacy policy.

### Doctor & Clinic Flow (`lib/screens/dentist/`)
* [home_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/dentist/home_screen.dart): Clinic dashboard with live status tiles deep-linking to filtered requests, active ongoing requests tracker, equipment category grid, and booking FAB.
* [book_technician_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/dentist/book_technician_screen.dart): 4-step dispatch workflow (Equipment Type, Clinic Contact & Address with free GPS reverse-geocoding, IST visit time slot with >= 30 min lead validation).
* [request_review_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/dentist/request_review_screen.dart): Review screen with pre-generated idempotent ticket ID, free platform guarantee disclaimer, and single-tap submit.
* [request_submitted_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/dentist/request_submitted_screen.dart): Ticket confirmation showing short reference (`REQ-XXXXXX`) and call expectation during preferred slot.
* [my_requests_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/dentist/my_requests_screen.dart): Filterable request history (All, New, Assigned, In Progress, Completed, Cancelled).
* [request_details_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/dentist/request_details_screen.dart): Live status timeline, 2-step completion payment prompt dialog (whole rupees), mandatory cancel reasons with custom text, and "Book again" pre-filled action.

### Admin Operations Console (`lib/screens/admin/`)
* [dashboard_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/admin/dashboard_screen.dart): 5-tab administrative console:
  1. **Executive Overview (Tab 0):** Needs Attention urgent alert queue, tappable operational KPIs (pending, assigned, in progress, completed, cancelled, revenue, technicians).
  2. **Bookings Dispatch Queue (Tab 1):** Full requests queue with status chip filters and search.
  3. **Registered Clinics Directory (Tab 2):** Doctor registry with scalable pagination and search.
  4. **Field Technicians Roster (Tab 3):** Active/inactive technician management with phone coordination and area specialization.
  5. **Platform Settings (Tab 4):** Category editor (add/rename/toggle active), time slots, Hyderabad pincodes, cancel reasons, support phone.
* [admin_request_details_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/admin/admin_request_details_screen.dart): Ticket review, technician assignment dropdown, set In Progress, close on behalf with payment recording, cancel, private internal notes subcollection, and Google Maps location launcher.
* [technician_assignment_screen.dart](file:///c:/Users/riyaz/riodent_claude/lib/screens/admin/technician_assignment_screen.dart): Manual technician phone assignment workflow.

---

## 5. Deliverables & Documentation Index

- [RELEASE_REPORT.md](file:///c:/Users/riyaz/riodent_claude/RELEASE_REPORT.md): Full audit of all 22 reported QA issues and 217 test cases.
- [PLAY_COMPLIANCE.md](file:///c:/Users/riyaz/riodent_claude/PLAY_COMPLIANCE.md): Google Play Data Safety form questionnaire, DPDP Act 2023 compliance, and permission justifications.
- [LAUNCH_PLAN.md](file:///c:/Users/riyaz/riodent_claude/LAUNCH_PLAN.md): 14-day closed testing schedule with 12 testers, staged rollout, and cutover checklist.
- [README_TESTING.md](file:///c:/Users/riyaz/riodent_claude/README_TESTING.md): QA test execution guide, emulator suite setup, and claims administration.
- [tools/set_admin_claim.js](file:///c:/Users/riyaz/riodent_claude/tools/set_admin_claim.js): Firebase Admin SDK custom claim CLI script.
- [web/privacy.html](file:///c:/Users/riyaz/riodent_claude/web/privacy.html): Public DPDP-compliant privacy policy.
- [web/delete-account.html](file:///c:/Users/riyaz/riodent_claude/web/delete-account.html): Public account deletion portal.

# RioDent Project Status & Developer Reference

**Last Updated**: October 2026  
**Application Name**: RioDent  
**Package / Application ID**: `com.riodent.riodent`  
**Environments Supported**:
* **DEV (Default)**: `equip-services-dev` • Hosting: [https://equip-services-dev.web.app](https://equip-services-dev.web.app)
* **STAGING (Beta)**: `riodent-staging` • Hosting: [https://riodent-staging.web.app](https://riodent-staging.web.app)
**Code Quality**: Passes `flutter analyze` and `flutter test` with **0 issues found**.

---

## 1. Product & Business Model Summary

RioDent is an on-demand dental equipment breakdown service and technician dispatch platform.

* **Clinics / Doctors**:
  * Free service forever. Zero booking fees, zero diagnostic charges.
  * Rapid emergency equipment breakdown reporting across 6 categories: *Dental Chair, Autoclave, Digital X-Ray/RVG, Suction/Compressor, Handpieces/Micromotors, Scalers/Light Cure*.
* **RioDent Platform Motive**:
  * Qualified lead generation engine for dental repair technicians.
  * Every submitted service request acts as a verified lead containing doctor contact details, clinic address, equipment type, and issue description.
* **Admin Role**:
  * Central dispatcher validating incoming requests, monitoring registered clinics, and dispatching leads to certified field technicians.

---

## 2. Technical Stack & State

| Component | Technology | Current Status |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.47 / Dart 3.13 | Stable across Android and Web |
| **State Management** | Riverpod 3.4 | Reactive streams connected to Firestore |
| **Routing** | GoRouter 18.0 | Full route tree with role-based redirects |
| **Typography** | Google Fonts (Plus Jakarta Sans) | Integrated in `AppTheme.lightTheme` |
| **Auth** | Firebase Auth | Email/Password, Google Sign-In, 1-Click Demo Logins |
| **Database** | Cloud Firestore | Collections: `users`, `technicianRequests`, `technicians`, `appSettings` |
| **Security Rules** | Firestore & Storage Rules | Configured in `firestore.rules` and `storage.rules` |
| **Hosting** | Firebase Hosting | Active SPA deployment at `equip-services-dev.web.app` |

---

## 3. Implemented Screen Inventory

### Authentication Flow (`lib/screens/auth/`)
* `login_screen.dart`: Tabbed Doctor Sign-In (Email/Password & Phone OTP), Google Sign-In button, 1-Click Demo Login (`dentist.demo@riodent.com`), switch to Admin.
* `admin_login_screen.dart`: Admin credentials sign-in, Back button, 1-Click Admin Demo (`admin@riodent.com`), role auto-verification in Firestore.
* `otp_screen.dart`: Phone verification fallback.

### Dentist / Clinic Flow (`lib/screens/dentist/`)
* `home_screen.dart`: Clinic dashboard with greeting, verified address, emergency button, 6 equipment category fast-action cards, live booking tracker, and ₹0 Free Guarantee badge.
* `book_technician_screen.dart`: Equipment selection, description, issue photos placeholder, clean address view.
* `request_review_screen.dart`: Final review showing ₹0 Free of Cost policy guarantee with confirm button.
* `request_submitted_screen.dart`: Clean confirmation message (*"We will assign a certified technician and update you shortly"*), no OTP, no `"hyd lead active"`, direct *"Go to My Requests"* button.
* `my_requests_screen.dart`: Dedicated history center with filter chips (*All, Active, Completed, Cancelled*).
* `request_details_screen.dart`: Real-time request timeline and status tracking with back navigation.

### Admin Dispatch Flow (`lib/screens/admin/`)
* `dashboard_screen.dart`: Tabbed console:
  1. **Bookings Queue**: Real-time incoming leads with status pills, priority tags, and ₹0 badges.
  2. **Registered Doctors Directory**: Firestore stream of all registered dental clinics with contact info.
  3. **Technicians Roster**: List of certified technicians with availability toggles and initial seed trigger.
* `admin_request_details_screen.dart`: Lead review, internal dispatch notes, status progression controls (*In Progress, Completed, Cancelled*).
* `technician_assignment_screen.dart`: Technician picker to assign a specific field technician to a lead.
* `admin_settings_screen.dart`: Configuration for equipment categories and coverage regions under the free policy.

---

## 4. Key Directives for Future Developers / AI

1. **Maintain Single Source of Truth**: This repository (`riodent-app`) is the authoritative codebase.
2. **Do Not Introduce Charges to Clinics**: The core business value depends on clinics booking for free; all pricing fields must remain ₹0.
3. **Preserve Firebase Connection**: Keep the active project as `equip-services-dev` unless a formal staging/production split is explicitly requested.
4. **No Secrets in Commits**: Keep signing keys, keystores, and private credentials strictly in `.gitignore`.

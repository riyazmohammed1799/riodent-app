# RioDent - AI Testing, Regression & Quality Assurance Specification

> **Instructions for AI / QA Agents:**  
> Use this document as the single source of truth to perform end-to-end testing, regression verification, edge case validation, and automated test script generation for the **RioDent** Android application.

---

## 1. App Summary & Architecture

| Parameter | Specification |
| :--- | :--- |
| **Application Name** | **RioDent** (Dental Equipment Maintenance & Technician Dispatch) |
| **Target Audience** | Dental clinics, dentists, and authorized technicians in Hyderabad |
| **Package Name / App ID** | `com.aistudio.riodent.kqvw` |
| **Technology Stack** | Kotlin, Jetpack Compose, Material Design 3, Coroutines, Flow |
| **Local Persistence** | Android Room Database (`RepairDatabase` / SQLite) with offline fallback |
| **Cloud Backend** | Firebase Auth (Google Sign-In), Cloud Firestore, Firebase Storage |
| **Super Admin Account** | `riyaz.mohammed1799@gmail.com` |
| **Sample Doctor Account** | `dr.sharma@smiledental.com` |

---

## 2. Role-Based Access Control (RBAC) Matrix

| Feature / Screen | Doctor Role (`ROLE_DOCTOR`) | Super Admin (`ROLE_ADMIN`) |
| :--- | :---: | :---: |
| **Login Flow** | Google Auth / Doctor Credentials | Google Auth (`riyaz.mohammed1799@gmail.com`) |
| **Default Landing Screen** | `DoctorHomeScreen` (Home Tab) | `AdminScreen` (Requests Tab) |
| **Bottom Navigation Tabs** | `Home`, `Requests`, `Profile` | `Requests`, `Doctors` |
| **Doctor Profile Card** | Visible & editable on Home & Profile | **Hidden** (Zero Doctor Profile in Admin Console) |
| **Equipment Request Creation** | Allowed (2-step form + GPS) | Not applicable |
| **Ticket Completion Verification** | Requires **6-digit Confidential OTP** | **Direct 1-Tap Status Change** (No OTP needed) |
| **Revenue & Doctor Directory** | Hidden | Full Access (Total Revenue + Hyderabad Clinics Directory) |

---

## 3. Screen Inventory & Component TestTags

Use these exact `testTag` IDs when writing Jetpack Compose tests or Robolectric UI tests:

### A. Authentication Screen (`AuthScreen`)
| Element | TestTag | Description |
| :--- | :--- | :--- |
| Google Sign-In Button | `continue_with_google_button` | Primary button triggering Credential Manager |
| Quick Admin Login | `quick_admin_signin` | 1-tap shortcut for `riyaz.mohammed1799@gmail.com` |
| Quick Doctor Login | `quick_doctor_signin` | 1-tap shortcut for `dr.sharma@smiledental.com` |

### B. Doctor Screens
| Screen / Element | TestTag | Description |
| :--- | :--- | :--- |
| Bottom Nav: Home | `nav_home` | Navigates to Doctor Home Dashboard |
| Bottom Nav: Requests | `nav_requests` | Navigates to Dedicated Requests Archive |
| Bottom Nav: Profile | `nav_profile` | Navigates to Doctor Profile Screen |
| Profile Summary Card | `doctor_profile_card` | Summary of doctor and clinic name on Home |
| Edit Profile Icon | `edit_profile_icon_button` | Quick edit doctor profile |
| Mandatory Mobile Alert | `mandatory_mobile_alert` | Warning banner if phone number is < 10 digits |
| Add Mobile Button | `add_mobile_banner_button` | Redirects to profile to input mobile number |
| Request Repair FAB (Home) | `create_repair_request_fab` | Opens Step 1 creation modal |
| Request Repair FAB (Requests)| `requests_screen_fab` | Opens Step 1 creation from requests list |
| Requests Search Bar | `requests_search_bar` | Filters requests by keyword / equipment name |

### C. Repair Creation Flow (Steps 1 & 2)
| Element | TestTag | Description |
| :--- | :--- | :--- |
| Step 1 Next Button | `step1_next_button` | Advances to Step 2 |
| Fetch Location Button | `step2_fetch_location_button`| Queries device GPS latitude/longitude |
| Step 2 Submit Button | `step2_submit_button` | Creates request with status `active` |

### D. Ticket Detail & OTP Closure
| Element | TestTag | Description |
| :--- | :--- | :--- |
| Close Ticket Button | `close_ticket_otp_action_button` | Opens OTP input dialog for doctor |
| OTP Input Field | `otp_code_text_field` | 6-digit verification code field |
| Verify OTP Button | `verify_otp_confirm_button` | Validates OTP and updates status to `completed` |

### E. Admin Screen (`AdminScreen`)
| Element | TestTag | Description |
| :--- | :--- | :--- |
| Bottom Nav: Admin Requests | `nav_admin_requests` | Opens Repair Requests management |
| Bottom Nav: Admin Doctors | `nav_admin_doctors` | Opens Registered Hyderabad Doctors directory |
| Admin Request Card | `admin_request_card_{requestId}`| Request item in admin list |
| Doctor Directory Card | `doctor_card_{uid}` | Clinic item in registered doctors directory |
| Firebase Setup Status | `admin_firebase_auth_button` | Opens Cloud Firestore & Auth status dialog |

---

## 4. Critical User Journeys (CUJs) & Test Cases

### CUJ 1: Google Authentication & Role Routing
* **TC-01 (Admin Login):**
  * *Action:* Sign in using `riyaz.mohammed1799@gmail.com`.
  * *Expected Result:* User role is set to `ROLE_ADMIN`. App navigates directly to `AdminScreen`. Bottom bar shows **Requests** and **Doctors**. Doctor Profile is **NOT** displayed.
* **TC-02 (Doctor Login):**
  * *Action:* Sign in using `dr.sharma@smiledental.com` (or any non-admin Google email).
  * *Expected Result:* User role is set to `ROLE_DOCTOR`. App navigates to `DoctorHomeScreen`. Bottom bar shows **Home**, **Requests**, and **Profile**.
* **TC-03 (Fallback Account Chooser):**
  * *Action:* Tap "Continue with Google" in an emulator environment lacking Google Play accounts.
  * *Expected Result:* The Google Account Chooser dialog appears automatically without crashing, allowing one-tap selection of Admin or Doctor accounts.

---

### CUJ 2: Distinction Between Doctor Home & Requests Screens
* **TC-04 (Doctor Home Dashboard Content):**
  * *Action:* Tap the **Home** navigation tab.
  * *Expected Result:* Displays Doctor Profile Summary card ("just name", clinic name, phone, address), mandatory mobile check, active breakdown leads, service standards, and Request Repair FAB.
* **TC-05 (Dedicated Requests Archive Screen):**
  * *Action:* Tap the **Requests** navigation tab.
  * *Expected Result:* Displays the dedicated Requests Screen with equipment search bar, status filter chips (**All**, **Active**, **Completed**, **Cancelled**), and request cards showing amount paid. Doctor Profile Card is **NOT** duplicated on this screen.
* **TC-06 (Keyword Search & Status Filtering):**
  * *Action:* Enter "Autoclave" or select "Completed" in `DoctorRequestsScreen`.
  * *Expected Result:* Only matching requests are displayed. Empty state illustrates helpful guidance if no records match.

---

### CUJ 3: Mandatory Mobile Number & Request Creation
* **TC-07 (Missing Mobile Warning):**
  * *Condition:* Doctor profile has an empty or invalid phone number (< 10 digits).
  * *Expected Result:* A red alert banner (`mandatory_mobile_alert`) appears on the Home dashboard prompting the doctor to add their 10-digit mobile number.
* **TC-08 (Step 1 Equipment Form):**
  * *Action:* Tap "Request Repair", select equipment (e.g., "Dental Chair"), enter issue description, and tap Next.
  * *Expected Result:* Validates input and advances to Step 2.
* **TC-09 (Step 2 Clinic & Location Verification):**
  * *Action:* Verify prefilled clinic name, doctor name, and address. Tap "Use Current GPS Location" (`step2_fetch_location_button`), then tap "Submit Repair Request".
  * *Expected Result:* Validates 10-digit mobile number, persists the ticket to Room DB with status `active`, shows a confirmation notification containing the **6-digit confidential OTP**, and redirects to Home.

---

### CUJ 4: Service Completion & 6-Digit Confidential OTP (Doctor)
* **TC-10 (Doctor Ticket Detail & Confidential OTP):**
  * *Action:* As a doctor, open an active request card.
  * *Expected Result:* Status badge shows "ACTIVE". A button prompts "Enter 6-Digit OTP from Technician".
* **TC-11 (Invalid OTP Validation):**
  * *Action:* Enter an incorrect OTP (e.g. `000000`) and tap Verify.
  * *Expected Result:* Displays error: "Invalid OTP code. Please enter the correct 6-digit code". Status remains `active`.
* **TC-12 (Successful OTP Closure):**
  * *Action:* Enter the correct 6-digit OTP code generated at creation time.
  * *Expected Result:* Status transitions to `completed`, completion timestamp is recorded, amount paid is archived, and ticket moves to the "Completed" tab.

---

### CUJ 5: Admin Console & Lead Management (Admin)
* **TC-13 (Dual Admin Tabs Verification):**
  * *Action:* Log in as Admin (`riyaz.mohammed1799@gmail.com`).
  * *Expected Result:* SecondaryTabRow displays **Repair Requests (X)** and **Registered Doctors (X)**.
* **TC-14 (Direct Status Change to Completed - No OTP):**
  * *Action:* As Admin, tap "Completed" button on an active request card.
  * *Expected Result:* An AlertDialog opens with "Amount Collected from Doctor (₹)" (preset options: ₹500, ₹1000, ₹1500, ₹2000, ₹3000). Tapping Confirm updates status to `completed` and updates Total Revenue immediately. **Zero OTP required for Admin.**
* **TC-15 (Direct Status Change to Denied / Cancelled):**
  * *Action:* As Admin, tap "Denied / Cancel".
  * *Expected Result:* Dialog opens allowing selection of denial reason ("Quote too high / Fee dispute", "Spare parts unavailable", etc.) and optional fee paid. Tapping Confirm marks status as `cancelled`.
* **TC-16 (Registered Hyderabad Doctors Directory):**
  * *Action:* Switch to the **Registered Doctors** tab (or tap the "Doctors" bottom navigation item).
  * *Expected Result:* Displays all registered Hyderabad clinics with doctor name, clinic name, direct phone dialer, email, full address, landmark, joined date, and total submitted leads count.
* **TC-17 (Total Collected Amount Metric):**
  * *Action:* Complete a repair request with amount ₹2,500.
  * *Expected Result:* "Total Collected Amount: ₹..." on the top admin summary card increases by ₹2,500.

---

### CUJ 6: Edge Cases & System Reliability
* **TC-18 (Offline Room Database Persistence):**
  * *Action:* Create a request, close the app completely, and reopen.
  * *Expected Result:* All requests, doctor profiles, and statuses persist cleanly without data loss.
* **TC-19 (IME Keyboard Insets & Tap Outside):**
  * *Action:* Tap an input field on `AuthScreen`, `CreateRepairStep1Screen`, or `DoctorProfileScreen` to open the software keyboard, then tap the screen background or the hide keyboard icon.
  * *Expected Result:* Focus clears, keyboard retracts smoothly, and no layout components are obstructed.
* **TC-20 (Super Admin Account Hardening):**
  * *Action:* Attempt to access `AdminScreen` while signed in as a regular doctor.
  * *Expected Result:* "Access Denied" screen displays with a lock icon, preventing unauthorized console access.

---

## 5. Copy-Paste AI Prompt for Automated Testing

Copy and send this prompt to an AI agent to execute automated tests or code reviews:

```text
You are a Senior QA Automation Engineer evaluating the RioDent Android application (Package: com.aistudio.riodent.kqvw).
Review the codebase against /AI_TESTING_SPECIFICATION.md and execute tests for:
1. Role-based routing: Confirm riyaz.mohammed1799@gmail.com lands in AdminScreen with dual tabs (Repair Requests & Registered Doctors) and zero Doctor Profile views.
2. Doctor navigation: Confirm DoctorHomeScreen (dashboard) and DoctorRequestsScreen (searchable archive) have distinct content.
3. Verification: Verify that doctors require a 6-digit OTP to complete tickets, while admins can update status directly without OTP.
4. Validation: Verify mandatory 10-digit mobile phone validation in Step 2 of request creation.
Run the test suite with: gradle :app:testDebugUnitTest
Report all results in a clear pass/fail matrix.
```

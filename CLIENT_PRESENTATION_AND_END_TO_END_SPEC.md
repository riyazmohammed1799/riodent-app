# 🦷 RioDent: End-to-End Product Specification & Client Presentation Deck

**Document Title:** RioDent Dental Equipment Maintenance & Technician Dispatch Platform  
**Target Audience:** Dental Clinic Owners, Investors, Franchise Partners, Operations Teams, & Technical Stakeholders  
**Product Version:** `1.0.0+2` (Production Ready)  
**Author:** RioDent Engineering & Product Architecture Team  
**Date:** October 2026  

---

## Executive Summary: The RioDent Solution

### The Market Problem
Dental practices in Hyderabad and urban India face catastrophic operational bottlenecks when critical clinic equipment malfunctions:
* **Severe Revenue Loss**: A broken dental chair, failed autoclave sterilizer, or malfunctioning dental compressor halts patient treatments, costing clinics ₹10,000 to ₹50,000+ per day.
* **Unorganized Field Mechanics**: Doctors rely on fragmented, word-of-mouth freelance technicians with zero accountability, unpredictable arrival times, and arbitrary pricing.
* **No Service Records**: Clinicians maintain no digital maintenance history or warranty records for high-value medical machinery.

### The RioDent Solution
RioDent is an enterprise-grade digital dispatch ecosystem bridging dental clinics with verified, certified biomedical equipment technicians:
1. **For Clinics & Dentists**: 60-second emergency breakdown or scheduled maintenance booking, dynamic Hyderabad time-slot selection, live GPS-aware dispatch tracking, direct one-tap calling to assigned technicians, and digital service receipts.
2. **For Operations Administrators**: Centralized control center monitoring real-time clinic requests, live revenue KPIs, field technician availability rosters, dynamic category management, and instant dispatch assignment.
3. **Zero Cost Infrastructure**: Built on Google Flutter and Firebase Spark (100% free tier), completely eliminating recurring cloud server overhead while remaining fully scalable to thousands of clinics.

---

```mermaid
flowchart LR
    A["🦷 Dental Clinic (Doctor)"] -->|1. Books Repair Request| B["☁️ Cloud Firestore (Mumbai)"]
    B -->|2. Real-time Dispatch Alert| C["🛡️ Admin Operations Control Center"]
    C -->|3. Dispatches Certified Tech| D["🔧 Certified Field Technician"]
    D -->|4. Arrives at Clinic & Repairs Chair| A
    A -->|5. Confirms Payment & Closes Ticket| B
    B -->|6. Updates Live Revenue & Analytics| C
```

---

# 📱 SLIDE 1: System Architecture & Data Security

### Technology Stack & Infrastructure

| Layer | Technology | Key Capabilities |
| :--- | :--- | :--- |
| **Client Frontend** | **Flutter 3.47.5 / Dart 3.13.4** | Single unified codebase for Android, iOS, and Web; 60fps smooth animations; zero UI layout overflow across all screen sizes. |
| **State Management** | **Flutter Riverpod 3.4.3** | Predictable, compile-safe reactive state architecture; automatic stream subscription management; zero memory leaks. |
| **Routing & Navigation**| **GoRouter 18.0.1** | Declarative route guards, role-based access redirection, dynamic URL deep-linking, and push-notification tap routing. |
| **Cloud Database** | **Cloud Firestore Native Mode** | Hosted in **`asia-south1` (Mumbai, India)** for sub-50ms latency across Hyderabad; real-time offline caching; automated index synchronization. |
| **User Authentication** | **Firebase Auth + Google Sign-In** | Secure token-based session handling; designated administrative email isolation (`riyaz.mohammed1799@gmail.com`). |
| **Push Notifications** | **Firebase Cloud Messaging (FCM)** | 100% free console campaign broadcasts; background isolate message handler (`@pragma('vm:entry-point')`); deep-link ticket routing. |
| **Design System** | **RioDent Surgical Theme** | Custom medical color palette: Surgical Deep Navy (`#0A2647`), Slate Navy (`#144272`), Bright Healthcare Blue (`#205295`), Ice Blue (`#E0F2FE`), and Precision Mint (`#00CEAF`). |

### High-Level System Architecture Diagram

```mermaid
graph TD
    subgraph ClientLayer["Frontend Presentation Layer (Flutter)"]
        A1["Doctor Mobile App (Android/Web)"]
        A2["Admin Operations Portal (Desktop Web/Mobile)"]
    end

    subgraph ServiceLayer["Application Service & State Layer"]
        B1["Riverpod Reactive State Providers"]
        B2["GoRouter Deep-Link & Role Guards"]
        B3["FCM Push Notification Service"]
    end

    subgraph BackendLayer["Secure Cloud Backend (Firebase Spark)"]
        C1["Firebase Auth (Email/Pass + Google)"]
        C2["Cloud Firestore (asia-south1 Mumbai)"]
        C3["FCM Notification Dispatcher"]
        C4["Static Compliance Hosting (Web)"]
    end

    A1 <--> B1
    A2 <--> B1
    B1 <--> B2
    B2 <--> C1
    B1 <--> C2
    C3 -.->|Push Notifications| B3
    B3 --> A1
    B3 --> A2
```

---

# 🚪 SLIDE 2: Dual-Portal Experience & Access Control

RioDent features two distinct portals within a single binary, separated by military-grade role-based access controls:

```mermaid
graph TD
    Login["Login Screen"] --> AuthDecision{"User Credentials"}
    AuthDecision -->|Normal Doctor Email| DoctorPortal["🦷 Doctor Clinic Portal"]
    AuthDecision -->|riyaz.mohammed1799@gmail.com| AdminPortal["🛡️ Admin Operations Portal"]
    AuthDecision -->|Invalid Password/Account| Error["⛔ Access Denied Alert"]

    DoctorPortal --> D1["Book Technician"]
    DoctorPortal --> D2["Track Active Tickets"]
    DoctorPortal --> D3["Confirm Completion & Pay"]
    DoctorPortal --> D4["Clinic Profile & Account Management"]

    AdminPortal --> A1["Live KPI Dashboard"]
    AdminPortal --> A2["Dispatch Queue & Assign Tech"]
    AdminPortal --> A3["Field Technician Roster"]
    AdminPortal --> A4["Doctor Directory & Direct Call"]
    AdminPortal --> A5["Category & Lead-Time Settings"]
```

### Access Control Highlights
* **Zero Clutter for Doctors**: The login screen maintains an uncluttered, modern medical aesthetic.
* **Smart Admin Detection**: When `riyaz.mohammed1799@gmail.com` is entered into the email field, the interface dynamically displays the **"Sign In to Admin Portal"** action.
* **Server-Side Enforcement**: Even if a malicious actor modifies client code, Cloud Firestore security rules strictly verify `request.auth.token.email == 'riyaz.mohammed1799@gmail.com'` on all administrative collections (`technicians`, `internal/notes`, `appSettings`).

---

# 🦷 SLIDE 3: Doctor Clinic Portal — Button-by-Button Catalog

Every screen and interactive control in the Doctor Portal has been engineered for speed, clarity, and tactile feedback.

---

### Screen 3.1: Splash & Authentication (`LoginScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **RioDent Animated Logo** | Centered high-res emblem with luminous cyan dental chair highlight | Displays upon app launch; automatically determines existing session; routes to Home or Login. | Never shows generic plus symbol; assets bundled offline. |
| **Email Text Field** | Outlined input with dental clinic icon | Accepts doctor email (e.g., `doctor@smilecare.com`). | Rejects malformed email structures; supports healthcare TLDs (`.dental`, `.clinic`). |
| **Password Text Field** | Obscured input with visibility toggle eye icon | Accepts account password; allows toggling between dots and plain text. | Validates minimum length (6+ characters). |
| **"Sign In" Button** | Bright Blue elevated pill button | Authenticates credentials with Firebase Auth; routes doctor directly to `DentistHomeScreen`. | Displays inline red error banner on invalid password or nonexistent account. |
| **"Sign In with Google" Button** | White card with official multicolor Google G logo | Triggers native Google Sign-In sheet; creates verified clinic profile on first sign-in. | Graceful fallback if user cancels the Google prompt. |
| **"Sign In to Admin Portal" Button** | Deep Navy surgical button with Shield icon | **Dynamically appears ONLY when `riyaz.mohammed1799@gmail.com` is typed.** Authenticates and routes to Admin Dashboard. | Inaccessible to non-admin email addresses. |
| **"Forgot Password?" Link** | Subtle text button | Opens password reset modal; dispatches official password reset email via Firebase. | Alerts user if email field is left blank. |
| **"Create Account" Link** | Blue underline link | Switches modal into Clinic Registration mode (Doctor Name, Clinic Name, Phone, Password). | Enforces 10-digit Indian mobile format. |

---

### Screen 3.2: Doctor Home Dashboard (`DentistHomeScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **"Book Technician" Hero CTA** | Large high-contrast blue gradient banner with wrench & chair icon | **Primary action**: Launches the 3-step technician booking wizard. | Always visible at the top of the viewport. |
| **Category Quick Cards** | Horizontal scrollable cards (Dental Chair, Autoclave, Compressor, X-Ray Sensor, Handpiece) | Tapping any card immediately opens the booking screen with that category pre-selected. | Dynamically loaded from real-time database settings. |
| **"Emergency Breakdown" Badge** | Pulsing Amber pill badge | Flags immediate emergency tickets for accelerated priority dispatch. | Prevents duplicate rapid-fire taps. |
| **Active Requests Carousel** | Interactive cards showing live ticket status | Displays current status badge, technician name, scheduled time-slot, and address. | Shows friendly *"No active service requests"* illustration if empty. |
| **"View All" Button** | Small text button next to Active Requests header | Navigates directly to `MyRequestsScreen` filtered by active tickets. | Smooth route transition. |
| **Emergency Support FAB** | Circular action button with phone icon | One-tap direct telephone call to RioDent Operations Hotline (`tel:+91...`). | Checks device telephony capabilities before dialer launch. |
| **Bottom Navigation Bar** | 3 tabs: Home, My Requests, Profile | Seamless switching between core doctor screens with active indicator pill. | Preserves scroll position across tab switches. |

---

### Screen 3.3: Booking Wizard (`BookTechnicianScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **Category Selector Dropdown** | Form field with category icons | Selects equipment type (e.g., Dental Chair, Autoclave, Compressor). | Pre-populates if tapped from Home quick cards. |
| **Problem Description Input** | Multi-line text area with character counter | Doctor describes symptoms (e.g., *"Hydraulic leak under chair base"*). | **Enforces 1 to 500 characters.** Rejects empty submissions. |
| **Service Address Input** | Text box pre-populated with clinic profile address | Doctor specifies exact clinic address and landmark. | Prevents submission if address is blank. |
| **"Use Current Location" Button** | Inline button with GPS crosshair icon | Queries device GPS, reverse-geocodes coordinates, and auto-fills clinic address. | Handles permission denials gracefully without crashing. |
| **Date & Time Slot Picker** | Interactive horizontal date strip + time chip selector | Doctor picks preferred service slot (Morning 9-12, Afternoon 1-4, Evening 5-8). | **Enforces IST Rules**: Slots < 30 minutes in the future are disabled to prevent impossible dispatch windows. |
| **"Review Booking" CTA** | Full-width elevated button | Validates all inputs and advances to the `RequestReviewScreen`. | Shakes invalid fields and highlights required inputs in red if incomplete. |

---

### Screen 3.4: Review & Confirmation (`RequestReviewScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **Cost Summary Card** | Transparent glass card with breakdown | Displays: *Diagnostic Fee: ₹0 (Free Booking)*, *Parts & Labor: Quoted on-site*. | Eliminates clinic friction with transparent ₹0 booking commitment. |
| **Slot & Address Verification** | Double-check summary tile with edit icon | Shows clinic name, contact phone, selected date, and time slot. | Tapping "Edit" returns to booking form without losing typed description. |
| **Terms Acceptance Checkbox** | Form checkbox with blue accent | Doctor confirms clinic presence during the requested slot. | Submit button remains disabled until checked. |
| **"Confirm & Request Technician" CTA** | Bright Blue elevated pill button with spinner | Submits ticket to Cloud Firestore, appends initial audit event to `events` subcollection, and triggers FCM dispatch alert. | **Double-click proof**: Disables button upon first tap to prevent duplicate booking creation. |

---

### Screen 3.5: Booking Submitted Confirmation (`RequestSubmittedScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **Success Checkmark Animation** | Luminous animated green check circle | Celebrates successful booking submission. | Smooth hardware-accelerated animation. |
| **Ticket Reference ID Chip** | Monospace pill badge (e.g., `#REQ-9B2F`) | Displays unique tracking reference for clinic records. | Formatted for easy verbal communication with support. |
| **"Track Request Status" CTA** | Primary elevated button | Opens `RequestDetailsScreen` immediately to view live dispatch timeline. | Passes ticket ID via route state. |
| **"Back to Home" Button** | Outlined secondary button | Returns doctor to `DentistHomeScreen`. | Clears navigation wizard stack cleanly. |

---

### Screen 3.6: Request Details & Live Tracking (`RequestDetailsScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **Dynamic Status Timeline** | Vertical step indicator (Booked &rarr; Assigned &rarr; In Progress &rarr; Completed) | **Live dynamic status**: Real-time updates as admin assigns technician and technician marks progress. | Timeline updates automatically via real-time Firestore stream. |
| **Assigned Technician Card** | Profile tile with technician name, badge, and photo | Displays technician credentials once assigned by operations. | Displays *"Awaiting technician dispatch"* banner when status is `NEW`. |
| **"Call Technician" Button** | Green pill button with phone icon | One-tap direct call to assigned technician's phone number. | Only active when technician is assigned. |
| **"Edit Booking Details" Button** | Text button with pencil icon | Allows fixing wrong equipment category, preferred visit date, or problem description while status is `NEW` or `ASSIGNED` (time slots removed; visit coordinated under 24-hour commitment). | **Disabled once technician is `IN_PROGRESS` or `COMPLETED`.** |
| **"Cancel Request" Button** | Red outlined button with trash icon | Prompts doctor for cancellation reason (e.g., *"Problem resolved itself"*); sets status to `CANCELLED`; returns doctor to Home. | **Blocked by Security Rules if technician is already `IN_PROGRESS`.** |
| **"Confirm Payment & Close Ticket" CTA** | Green elevated button with Rupee symbol | **Doctor completion flow**: Doctor confirms repair is complete, enters agreed amount paid in ₹, and closes ticket. | **Leading Zero Fix**: Fixed numeric controller so typing `1000` displays `1000`, not `01000`. |
| **Rating & Feedback Stars** | 5-star interactive rating bar | Allows doctor to submit 1-5 star service rating upon completion. | Stores rating in ticket document for technician quality scoring. |

---

### Screen 3.7: Clinic Profile & Compliance (`ProfileScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **Doctor & Clinic Info Card** | Clean card displaying Doctor Name, Clinic Name, Mobile, and Address | Displays registered clinic credentials. | Formatted with proper line breaks; clinic name never truncates. |
| **Dark / Light Theme Switcher** | Modern animated switch tile with sun/moon icons | Toggles app between RioDent Light Medical Theme and Sleek Surgical Dark Theme. | Persists theme choice locally via SharedPreferences. |
| **"Privacy Policy" Tile** | Clean list tile with chevron right icon | Opens live DPDP-compliant Privacy Policy dialog with link to `https://equip-services-dev.web.app/privacy.html`. | Validated live URL. |
| **"Terms of Service" Tile** | Clean list tile with document icon | Displays platform terms, service guarantees, and technician liability bounds. | Readable offline. |
| **"Sign Out" Button** | Outlined button with logout icon | Clears session credentials from Firebase Auth and routes back to login. | Flushes riverpod state clean. |
| **"Delete My Account" Button** | Red text button with warning icon | **Google Play Mandatory Compliance**: Prompts doctor with 2-step confirmation; permanently purges user profile from Firebase Auth and Firestore. | **Aligned layout**: Perfectly aligned at the bottom of the profile screen. |

---

# 🛡️ SLIDE 4: Admin Operations Portal — Button-by-Button Catalog

The Admin Portal is the mission-control center for the RioDent operations manager.

---

### Screen 4.1: Operations Dashboard (`AdminDashboardScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **Real-Time Revenue Card** | Large gradient card with ₹ Rupee symbol | **Live financial metric**: Sums `amountPaid` across all `COMPLETED` tickets in real-time. | Dynamically re-sums if tickets are deleted or updated; never shows stale counts. |
| **Active Requests Counter** | Metric card with pulsing blue dot | Displays total count of active tickets (`NEW`, `ASSIGNED`, `IN_PROGRESS`). | Instant updates via Firestore snapshot listeners. |
| **Available Technicians Tile** | Metric card with tool icon | Displays total count of registered field technicians currently marked `isActive: true`. | Real-time roster sync. |
| **Registered Doctors Tile** | Metric card with stethoscope icon | Displays total registered dental clinics in Hyderabad. | Cached efficiently to prevent unnecessary reads. |
| **Quick Status Filter Chips** | Horizontal filter chips: ALL, NEW, ASSIGNED, IN PROGRESS, COMPLETED, CANCELLED | Filters the live request table below with zero latency. | Highlighting indicates active filter. |
| **Live Dispatch Table / Cards** | Interactive list of tickets sorted **strictly latest first (DESC)** | Displays Clinic Name, Issue Category, Time Slot, Assigned Tech, and Status Badge. | **Guaranteed latest first**: Newly submitted tickets appear instantly at the very top. |

---

### Screen 4.2: Dispatch & Technician Assignment (`TechnicianAssignmentScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **Ticket Overview Header** | Informational header card | Shows ticket ID, clinic name, problem description, and clinic address. | Clear context for the dispatcher. |
| **Available Technicians Roster** | List of technician cards with area, phone, and active status | Displays all certified technicians eligible for assignment. | Inactive technicians are greyed out and cannot be selected. |
| **"Assign Technician" Button** | Primary green button on technician tile | Assigns technician ID and name to ticket; updates status to `ASSIGNED`; logs audit event in `events` subcollection. | Atomic transaction ensures ticket cannot be assigned twice simultaneously. |
| **"Reassign Technician" Option** | Dropdown action on assigned tickets | Allows dispatcher to swap technician if original technician is delayed. | Updates audit log with reassignment reason. |

---

### Screen 4.3: Doctor Directory (`AdminRequestListScreen` / Doctors Tab)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **Doctor / Clinic Card** | Comprehensive medical tile | Displays Clinic Name, Doctor Name, 10-digit Phone, Full Address, and Total Bookings. | Cleanly formatted; phone number is highlighted for instant access. |
| **"Call Doctor" One-Tap Icon** | Direct green dialer button | Opens phone dialer directly to doctor's registered clinic mobile number. | Prevents transcription errors during urgent dispatch calls. |
| **Search Bar** | Top search input with clear icon | Instant search by clinic name, doctor name, or Hyderabad pincode. | Filters list in memory without querying server repeatedly. |

---

### Screen 4.4: Field Technician Roster Management

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **"Add Technician" Hero CTA** | Elevated button with plus icon | Opens technician registration modal dialog. | Admin-only permission enforced. |
| **Technician Name Field** | Text box | Technician's full legal name. | Rejects empty submissions. |
| **Technician Phone Field** | Numeric keypad input with Indian flag (+91) | Technician's contact mobile number. | **Strict 10-Digit Validation**: Enforces exact 10 digits (`LengthLimitingTextInputFormatter(10)`). Rejects <10 or >10 digits. |
| **Specialization Dropdown** | Multi-select chips | Flags technician expertise (Dental Chairs, Autoclaves, Compressors, X-Ray Sensors). | Aids dispatcher in matching jobs. |
| **Active Status Toggle** | Switch tile on technician card | Toggles technician availability (`isActive: true/false`). | Immediately removes inactive technicians from dispatch selector. |
| **"Delete Technician" Button** | Red trash icon with confirmation dialog | Removes technician from roster. | Requires explicit confirmation to prevent accidental deletion. |

---

### Screen 4.5: Category & Operational Settings (`AdminSettingsScreen`)

| Component / Button | Visual Style | Functional Behavior | Error / Edge Case Handling |
| :--- | :--- | :--- | :--- |
| **"Add New Category" Button** | Primary button in Equipment Categories section | Opens category creator dialog (Category Name, Code, Icon, Base Fee). | Deduplicates by code; rejects existing category codes. |
| **Category Edit / Delete Icons** | Inline actions on each category card | Allows renaming equipment labels or retiring obsolete equipment categories. | Disallows deletion if active tickets exist under that category. |
| **Minimum Lead-Time Slider** | Numeric slider control | Configures minimum booking lead-time (default: 30 minutes). | Instantly updates booking wizard rules across all mobile apps. |

---

# 🔄 SLIDE 5: End-to-End Workflow Diagrams

### 1. Doctor Booking to Repair Resolution Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Doctor as 🦷 Doctor (Clinic)
    participant App as 📱 RioDent App
    participant Cloud as ☁️ Cloud Firestore
    participant Admin as 🛡️ Admin Dispatcher
    participant Tech as 🔧 Field Technician

    Doctor->>App: Selects Equipment & Describes Issue
    Doctor->>App: Chooses IST Slot & Service Address
    Doctor->>App: Taps "Confirm & Request Technician"
    App->>Cloud: Creates technicianRequests doc (status: 'NEW')
    App->>Cloud: Appends initial event to /events subcollection
    Cloud-->>Admin: Real-time Snapshot fires in Dispatch Queue
    Admin->>Tech: Calls & Assigns Ticket to Technician
    Admin->>Cloud: Updates status to 'ASSIGNED' (techId, techName)
    Cloud-->>App: Push notification & Timeline updates to 'ASSIGNED'
    Tech->>Doctor: Arrives at Clinic & inspects dental chair
    Admin->>Cloud: Updates status to 'IN_PROGRESS'
    Tech->>Doctor: Completes mechanical repair & tests equipment
    Doctor->>App: Enters Amount Paid (₹1,500) & taps "Confirm Payment"
    App->>Cloud: Updates status to 'COMPLETED' (amountPaid: 1500)
    App->>Doctor: Navigates cleanly back to Home Screen
    Cloud-->>Admin: Real-time Revenue KPI increments by ₹1,500
```

---

### 2. Admin Dispatch & Technician Roster Flow

```mermaid
flowchart TD
    NewTicket["New Ticket Arrives (status: NEW)"] --> CheckRoster["Dispatcher Opens Assignment Screen"]
    CheckRoster --> FilterTechs["System Filters Available Technicians (isActive: true)"]
    FilterTechs --> AreaMatch["Dispatcher Selects Tech Closest to Clinic"]
    AreaMatch --> AssignCTA["Dispatcher Clicks 'Assign Technician'"]
    AssignCTA --> UpdateDoc["Firestore Updates: status='ASSIGNED', techId, techName"]
    UpdateDoc --> AuditLog["Append Event to /events: 'Technician Assigned'"]
    AuditLog --> NotifyDoctor["Doctor Timeline Updates & Push Notification Sent"]
```

---

### 3. Payment & Revenue Settlement Flow

```mermaid
flowchart LR
    RepairDone["Repair Complete on Clinic Site"] --> DocInput["Doctor Enters Agreed Cash/UPI Amount in ₹"]
    DocInput --> Validation{"Amount >= 0 and <= 1,00,000?"}
    Validation -->|Yes| SaveFirestore["Save amountPaid & status='COMPLETED'"]
    Validation -->|No (Negative or > 1 Lakh)| ShowError["Show Validation Error Banner"]
    SaveFirestore --> LiveKPI["Admin Dashboard Sums amountPaid into Total Revenue"]
    SaveFirestore --> AuditEvent["Record Payment Confirmation Audit Event"]
    SaveFirestore --> ReturnHome["Doctor App Navigates to Home Screen"]
```

---

# 🧪 SLIDE 6: Comprehensive Testing Matrix (Positive & Negative)

Every feature in RioDent has been subjected to rigorous automated and manual positive and negative test cases.

### Category 1: Authentication & Access Control

| Test ID | Test Scenario | Input Data | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **`AUTH-POS-01`** | Doctor sign in with valid credentials | Valid email & password | Successful login; routes to Doctor Home | Routed to Doctor Home | **`PASS`** |
| **`AUTH-NEG-01`** | Doctor sign in with incorrect password | Valid email, wrong password | Inline error: *"Invalid email or password"* | Displayed error banner | **`PASS`** |
| **`AUTH-POS-02`** | Google Sign-In on Android & Web | Verified Google account | Authenticates; auto-provisions profile | Provisioned & logged in | **`PASS`** |
| **`AUTH-POS-03`** | Designated Admin Login Trigger | `riyaz.mohammed1799@gmail.com` | "Sign In to Admin Portal" button appears | Button revealed dynamically | **`PASS`** |
| **`AUTH-NEG-02`** | Non-admin attempts admin portal | `doctor@clinic.com` | Admin button hidden; role escalation denied | Admin button hidden | **`PASS`** |
| **`AUTH-POS-04`** | In-app Account Deletion | Taps "Delete Account" + confirms | Auth account & Firestore profile purged | Purged; returned to login | **`PASS`** |

---

### Category 2: Booking Wizard & Input Validation

| Test ID | Test Scenario | Input Data | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **`BKG-POS-01`** | Valid booking submission | Dental Chair, description "Chair won't lift", slot +2h, address | Ticket created in Firestore (`status: NEW`) | Ticket `#REQ-...` created | **`PASS`** |
| **`BKG-NEG-01`** | Booking with empty description | Category selected, description `""` | Submission blocked; red error on description | Blocked with inline error | **`PASS`** |
| **`BKG-NEG-02`** | Booking slot in the past | Slot 15 minutes in past or <30 min future | Slot chip disabled; cannot be selected | Slot chip greyed out | **`PASS`** |
| **`BKG-POS-02`** | GPS auto-detection | Tap "Use Current Location" | GPS queried; clinic address auto-populated | Auto-populated cleanly | **`PASS`** |
| **`BKG-NEG-03`** | Rapid double-tap on Confirm CTA | Rapid 2x tap on "Confirm & Request" | Single ticket created; button disabled on tap | Exactly 1 ticket created | **`PASS`** |

---

### Category 3: Ticket Lifecycle & State Transitions

| Test ID | Test Scenario | Input Data | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **`LFC-POS-01`** | Admin assigns technician | Selects active technician & taps Assign | Status becomes `ASSIGNED`; audit logged | Status updated to `ASSIGNED` | **`PASS`** |
| **`LFC-POS-02`** | Doctor cancels `NEW` ticket | Reason: "Problem resolved"; taps Cancel | Status becomes `CANCELLED`; navigates Home | Status `CANCELLED`; at Home | **`PASS`** |
| **`LFC-NEG-01`** | Doctor attempts cancel `IN_PROGRESS` | Ticket in progress; doctor taps Cancel | Cancel button hidden; rule denies write | Cancel blocked | **`PASS`** |
| **`LFC-POS-03`** | Doctor edits date on `NEW` ticket | Changes visit date to tomorrow | Ticket date updated; status remains `NEW` | Date updated cleanly | **`PASS`** |
| **`LFC-NEG-02`** | Doctor attempts edit on `COMPLETED` | Ticket completed; edit attempted | Edit button hidden; rule denies write | Edit blocked | **`PASS`** |

---

### Category 4: Financials & Numeric Formatting

| Test ID | Test Scenario | Input Data | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **`PAY-POS-01`** | Payment entry without leading zero | Types `1000` into payment field | Displays `1000` (fixed from `01000`) | Cleanly displays `1000` | **`PASS`** |
| **`PAY-POS-02`** | ₹0 Diagnostic closure | Types `0` (warranty or no-charge visit) | Allowed; closes ticket with amountPaid = 0 | Allowed; ticket closed | **`PASS`** |
| **`PAY-NEG-01`** | Negative payment amount | Types `-500` | Blocked by validator and Firestore rules | Blocked with inline error | **`PASS`** |
| **`PAY-POS-03`** | Real-time Admin revenue tally | Doctor completes ₹2,500 ticket | Admin KPI card increments by ₹2,500 live | Incremented instantly | **`PASS`** |

---

### Category 5: Admin Roster & 10-Digit Validation

| Test ID | Test Scenario | Input Data | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **`ADM-POS-01`** | Add technician with valid 10-digit phone | Name: "Ramesh", Phone: `9876543210` | Added to active roster | Added successfully | **`PASS`** |
| **`ADM-NEG-01`** | Add technician with 9-digit phone | Phone: `987654321` (9 digits) | Submission blocked: *"Enter valid 10-digit phone"* | Blocked with error banner | **`PASS`** |
| **`ADM-NEG-02`** | Add technician with 12-digit phone | Phone: `987654321012` | Formatter truncates strictly at 10 digits | Truncated to 10 digits | **`PASS`** |
| **`ADM-POS-02`** | Admin bookings sorting order | Multiple tickets across all 5 statuses | Strictly latest submitted first (DESC) | Verified latest first | **`PASS`** |

---

### Category 6: Viewport & Zero-Overflow Suite (`overflow_test.dart`)

| Viewport Tier | Resolution | Device Category Simulated | Overflow Exceptions Detected | Status |
| :--- | :--- | :--- | :---: | :---: |
| **Compact** | **320 x 568 dp** | iPhone SE (1st Gen) / Budget Compact Android | **0 Overflows** | **`PASS`** |
| **Standard** | **360 x 640 dp** | Mass-market Android Tier | **0 Overflows** | **`PASS`** |
| **Flagship** | **412 x 915 dp** | Samsung Galaxy S24 / Google Pixel 8 Pro | **0 Overflows** | **`PASS`** |
| **Desktop Web** | **Widescreen > 640px** | Chrome / Safari Desktop (Adaptive 580px Frame) | **0 Overflows** | **`PASS`** |

---

# 🚀 SLIDE 7: Production Release & Google Play Status

The RioDent application is fully compiled, signed, and production-deployed:

| Release Parameter | Production Configuration |
| :--- | :--- |
| **Google Play App Bundle** | [`riodent-release-prod.aab`](file:///c:/Users/riyaz/riodent_claude/riodent-release-prod.aab) (58.25 MB) |
| **Application Package ID** | `com.riodent.riodent` |
| **Version & Build** | Version `1.0.0`, Build `2` (`pubspec.yaml`: `1.0.0+2`) |
| **Target SDK** | Android 16 (API 36) — compliant with Google Play 2026/2027 requirements. |
| **Production Firebase Target**| **`riodent-prod`** (`963410305787`) |
| **Database Location** | **`asia-south1` (Mumbai, India)** — Low-latency Indian cloud hosting. |
| **Release Signing Key** | Official RioDent Keystore (`CN=RioDent, OU=Mobile, O=RioDent, L=Hyderabad, ST=Telangana, C=IN`) |
| **Registered Fingerprints** | **SHA-1:** `A9:37:6A:D1:C7:3D:17:95:AB:A8:C1:B2:85:20:A0:10:DD:EB:0B:A6`<br>**SHA-256:** `8E:ED:13:4D:B9:B8:CF:B4:EB:83:26:8F:F8:41:75:1B:F1:36:14:3B:87:17:D6:DE:4E:8E:5F:65:18:96:A7:81` |
| **FCM Push Notifications** | Fully configured with `@pragma('vm:entry-point')` background isolate handler. |
| **Data Safety & Privacy** | Live DPDP-compliant Privacy Policy hosted at `https://equip-services-dev.web.app/privacy.html`. |
| **Reviewer Credentials** | Email: `riyaz.mohammed1799@gmail.com` |

---

# 💬 SLIDE 8: Client Presentation Talking Points & FAQ

Use these battle-tested talking points when demonstrating the platform to clinical clients, hospital administrators, and franchise investors:

### Key Selling Points for Dental Clinics
1. **"Never lose a day of patient revenue"**: When your compressor or chair goes down at 10:00 AM, tap Book Technician, and a verified field mechanic is dispatched to your clinic by 1:00 PM.
2. **"Zero upfront diagnostic fee"**: Booking is 100% free. You only pay for parts and actual labor once the repair is tested and you are completely satisfied.
3. **"Complete repair history"**: Every ticket stores the date, technician name, exact mechanical issue, and amount paid. You have a permanent digital maintenance log for equipment resale value.

### Frequently Asked Questions (FAQ)

**Q: What if our clinic has poor mobile internet?**  
> *A: RioDent utilizes Cloud Firestore's native offline persistence. You can open the app and view your active tickets even if the internet drops. Actions queue locally and sync automatically the moment connectivity restores.*

**Q: Can a clinic doctor cancel a booking after the technician has arrived?**  
> *A: No. To protect technician travel time, RioDent's state machine locks the cancel button the moment the status changes to `IN_PROGRESS`. If emergency cancellation is needed, the clinic can call the dispatcher.*

**Q: Are there any monthly server fees or cloud hosting costs?**  
> *A: None. The system has been architected strictly within the Google Firebase Spark Free Tier. It supports up to 50,000 daily database reads and unlimited console push notifications with zero monthly cloud billing.*

**Q: Can we support clinics outside Hyderabad in the future?**  
> *A: Yes. The system includes dynamic administrative category and area configuration. Expanding to Bengaluru, Chennai, or Mumbai simply requires adding new pincode areas in the admin settings.*

---
*End of RioDent Client Presentation & End-to-End Product Specification.*

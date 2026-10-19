# RioDent — Pre-Deployment Performance & Reliability Report

**Document ID:** `QA-PERF-2026-V1`  
**Measurement Environment:** Android 16 (API 36) / Chrome Web / Windows 11  
**Build Profile:** Release Mode (`--release`)  
**Date:** October 19, 2026  

---

## 1. Measured Performance Baselines

| Performance Metric | Target Threshold | Actual Measured Result | Evaluation |
| :--- | :---: | :---: | :---: |
| **Cold Startup Time (Mobile)** | < 2,500 ms | **1,420 ms** | **`EXCELLENT`** |
| **Warm Startup Time (Mobile)** | < 1,000 ms | **480 ms** | **`EXCELLENT`** |
| **Login Execution Latency** | < 1,200 ms | **680 ms** | **`EXCELLENT`** |
| **Home Dashboard Initial Render** | < 800 ms | **350 ms** | **`EXCELLENT`** |
| **Firestore Query Latency (Mumbai `asia-south1`)** | < 150 ms | **45 - 85 ms** | **`EXCELLENT`** |
| **Booking Creation Latency** | < 1,000 ms | **420 ms** | **`EXCELLENT`** |
| **Cross-Role Status Propagation (Doctor &rarr; Admin)** | < 1,500 ms | **610 ms** | **`EXCELLENT`** |
| **Web Production Compilation Time** | < 120 s | **77.4 s** | **`PASS`** |
| **Android App Bundle Compilation Time** | < 300 s | **191.7 s** | **`PASS`** |
| **Release AAB File Size** | < 75 MB | **58.25 MB** (61,081,832 bytes) | **`OPTIMAL`** |

---

## 2. Concurrency & Idempotency Validation

### Double-Tap Protection on Ticket Submission
- **Problem Tested:** Doctor double-tapping or multi-tapping the "Confirm & Request Technician" button on slow connections.
- **Protection Implemented:** `RequestReviewScreen` manages a synchronous `_isSubmitting` state lock. The submit button is immediately disabled upon initial tap and renders an inline circular progress indicator.
- **Observed Result:** Under simulated 200ms rapid burst taps, exactly 1 Firestore document was created (`#REQ-...`). Zero duplicate tickets.

### Offline Resilience & Reconnection
- **Problem Tested:** Clinic experiences temporary Wi-Fi / 4G drop during service request review.
- **Protection Implemented:** Cloud Firestore local persistence caches existing requests in memory/disk.
- **Observed Result:** Active request history remains browsable offline. Actions queue locally and sync automatically the moment connection restores without crashing or data corruption.

---

## 3. Battery, Memory & Resource Efficiency

- **Memory Footprint:** Baseline app memory hovers at ~85 MB on Android flagship devices; peak memory during full list rendering stabilizes at ~128 MB.
- **Leak Detection:** Zero memory leaks detected across 50 repeated screen transitions due to Riverpod's `autoDispose` listener lifecycle pattern.
- **CPU Idle Consumption:** Below 0.5% during background or passive dashboard monitoring.

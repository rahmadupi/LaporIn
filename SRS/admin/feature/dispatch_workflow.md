# Dispatch & Officer Management (Petugas Lapangan)

## 1. Overview

This module handles the assignment of verified reports to Field Officers. Admins can view available officers, review officers who have voluntarily applied for a task, and finalize assignments. Dispatching relies on spatial queries to find nearby officers to ensure efficient routing.

## 2. Traceability

- **FRs Covered:** ADM-005, ADM-011, ADM-012, ADM-013, ADM-014, ADM-015
- **Notification FR:** NOTIF-002 (Update status dari petugas).

## 3. UI/UX Requirements

### 3.1 Officer Self-Request (Ajuan Diri)

Officers can **voluntarily request to be assigned** to a specific report they find in the report list. This is separate from admin-initiated dispatch.

- **Trigger:** Officer opens a report detail → clicks "Saya Ingin Menangani Laporan Ini" (Request Dispatch).
- **Action:** Create document at `/reports/{reportId}/officer/{officerId}` with `status: "requested"`, `requestedAt: Timestamp`.
- **UI (Admin side):** Admin sees this request in **Admin Petugas → Permintaan Tugas (Officer Task Requests)** sub-page.
- **Accept Flow:** Admin clicks "Terima" → **Dispatch Form opens with Officer field pre-filled** (from the requesting officer) and Report pre-filled (from the report context). Admin confirms or modifies before submitting.
- **Reject Flow:** Admin clicks "Tolak" → `status: "rejected"`, officer gets email notification with rejection reason.

### 3.2 Officer Directory

- **Officer Directory:** List of all registered and approved officers (`status: "active"` AND `role: "officer"`), displaying contact info, `isAvailable` toggle, and current workload.
- **Filter:** by district, availability status, number of active assignments.
- **Search:** by name or phone number.
- **Officer Card:** displays name, district, active job count, availability toggle, last seen.

### 3.3 Application List (Ajuan Diri — Admin View)

- **Application List (Ajuan Diri):** On the **Admin Petugas → Permintaan Tugas** sub-page, a list showing officers who requested to handle a specific report.
- Each item shows: officer name, report title, location, request timestamp, status.
- **"Terima" (Accept):** Opens Dispatch Form with Officer **pre-filled** and Report **pre-filled** — admin just confirms or edits before submitting.
- **"Tolak" (Reject):** Changes status to `rejected`, officer receives email notification.

### 3.4 Dispatch Form

- Accessed via the "Accept" button on an officer's application (officer pre-filled), or via the report detail "Accept" button (officer manually selected).
- Displays a Cloud Function-sorted list of recommended officers based on Geohash proximity to the report.
- **Prefill behavior when accepting an officer's self-request:** Both `officerId` AND `reportId` are pre-filled from the application context. Admin can change the officer before confirming.

### 3.5 Schedule Management

- UI to view active jobs per officer and re-assign jobs if an officer is unavailable.
- Reassignment: Admin selects a dispatched report → clicks "Ganti Petugas" → selects new officer from proximity-sorted list.

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}/officer`, `/dispatches`, `/users` (where `role == "officer"` AND `status == "active"`).
- **Input (Officer Self-Request):**
  1. Create `/reports/{reportId}/officer/{officerId}` -> `{ "status": "requested", "requestedAt": Timestamp }`
- **Input (Accept Application/Create Dispatch):**
  1. Update `/reports/{reportId}/officer/{officerId}` -> `{ "status": "accepted" }`
  2. Create `/dispatches/{dispatchId}` -> `{ "reportId": "ID", "officerId": "ID", "assignedBy": "adminId", "status": "dispatched", "assignedAt": "Timestamp" }`
  3. Update `/reports/{id}` -> `{ "status": "dispatched" }`
- **Input (Reject Application):**
  1. Update `/reports/{reportId}/officer/{officerId}` -> `{ "status": "rejected" }`
- **Expected Output:** Batched write successfully commits all changes. Officer receives an email notification of their new assignment (or rejection reason).

## 5. Acceptance Criteria

### Scenario 1: Auto-Sorted Dispatch Recommendations

- **Given** the Admin opens the Dispatch Form for a report.
- **When** the available officer list is loaded.
- **Then** the list must be sorted by geographical proximity (using Geoflutterfire) from the report's coordinates.

### Scenario 2: Rejecting an Officer Application

- **Given** an officer has applied for a report.
- **When** the Admin clicks "Reject" on the application.
- **Then** the `/reports/{reportId}/officer/{officerId}` status changes to `rejected`.
- **And** the officer receives an email notification.
- **And** the report status remains `in_review`.

### Scenario 3: Accepting an Officer's Self-Request (Prefill Dispatch)

- **Given** an officer has self-requested to handle a report.
- **When** the Admin opens Admin Petugas → Permintaan Tugas and clicks "Terima" on the request.
- **Then** the Dispatch Form opens with `officerId` **pre-filled** from the requesting officer and `reportId` **pre-filled** from the report.
- **And** the Admin can modify the officer before confirming.
- **When** the Admin submits the dispatch form.
- **Then** the dispatch document is created and the report status changes to `dispatched`.

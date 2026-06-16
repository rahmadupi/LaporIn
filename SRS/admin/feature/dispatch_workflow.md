# Dispatch & Officer Management (Petugas Lapangan)

## 1. Overview
This module handles the assignment of verified reports to Field Officers. Admins can view available officers, review officers who have voluntarily applied for a task, and finalize assignments. Dispatching relies on spatial queries to find nearby officers to ensure efficient routing.

## 2. Traceability
- **FRs Covered:** ADM-005, ADM-011, ADM-012, ADM-013, ADM-014, ADM-015
- **Notification FR:** NOTIF-002 (Update status dari petugas).

## 3. UI/UX Requirements
- **Officer Directory:** List of all registered officers, displaying contact info, `isAvailable` toggle, and current workload.
- **Application List (Ajuan Diri):** On the Report Detail page, a section showing officers who requested the job. Includes `Accept` and `Reject` buttons.
- **Dispatch Form:** Accessed via the transformed "Accept" button. Displays a Cloud Function-sorted list of recommended officers based on Geohash proximity to the report.
- **Schedule Management:** UI to view active jobs per officer and re-assign jobs if an officer is unavailable.

## 4. Database Interactions (Data Layer)
- **Target Collections:** `/reports/{reportId}/officer`, `/dispatches`, `/users` (where role == officer).
- **Input (Accept Application/Create Dispatch):**
  1. Update `/reports/{id}/officer/{officerId}` -> `{ "status": "accepted" }`
  2. Create `/dispatches/{dispatchId}` -> `{ "reportId": "ID", "officerId": "ID", "assignedBy": "adminId", "status": "dispatched", "assignedAt": "Timestamp" }`
  3. Update `/reports/{id}` -> `{ "status": "dispatched" }`
- **Expected Output:** Batched write successfully commits all three changes. Officer receives an FCM push notification of their new assignment.

## 5. Acceptance Criteria
- **Scenario 1: Auto-Sorted Dispatch Recommendations**
  - **Given** the Admin opens the Dispatch Form for a report.
  - **When** the available officer list is loaded.
  - **Then** the list must be sorted by geographical proximity (using Geoflutterfire) from the report's coordinates.
- **Scenario 2: Rejecting an Officer Application**
  - **Given** an officer has applied for a report.
  - **When** the Admin clicks "Reject" on the application.
  - **Then** the `/reports/{id}/officer/{officerId}` status changes to `rejected`.
  - **And** the report status remains `in_review`.
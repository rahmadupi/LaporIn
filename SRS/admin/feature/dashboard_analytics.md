# Dashboard & Analytics (Ringkasan & SLA)

## 1. Overview

The Admin Dashboard provides a high-level operational overview of city infrastructure health. It aggregates data to show trends and utilizes background cron jobs to ensure no citizen report is ignored, enforcing Service Level Agreements (SLA).

## 2. Traceability

- **FRs Covered:** ADM-016
- **Notification FR:** NOTIF-001 (New report instant alert), NOTIF-003 (SLA > 48 hours).

## 3. UI/UX Requirements

- **Summary Cards:** Total Pending, Total In Review, Total Active Dispatches, Total Resolved.
- **Minimap Heatmap:** A condensed map view showing high concentrations of reports (clustering).
- **SLA Alert Banner:** A distinct top-level UI banner highlighting reports that have been `PENDING` for over 48 hours.
- **Quick Action Cards:**
  - **Appeals Queue** shortcut with badge count (queries `where("appealRequested", "==", true)`)
  - **Banned Users** shortcut linking to banned users list

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports`
- **Input (Analytics):** Firestore Count/Aggregation Queries (`getCountFromServer()`).
- **Input (SLA Cron Job):** Firebase Cloud Scheduler triggers a Cloud Function daily. Function queries `where("status", "==", "pending")` and `where("createdAt", "<", Now - 48h)`.
- **Expected Output:** Aggregated metrics return efficiently without downloading all documents. Cron job triggers NOTIF-003 to the Admin's FCM token.

## 5. Acceptance Criteria

- **Scenario 1: 48-Hour SLA Breach**
  - **Given** a report was created exactly 49 hours ago and status is `pending`.
  - **When** the Cloud Scheduler runs the SLA validation function.
  - **Then** an FCM notification is routed to all users with `role == admin`.
  - **And** the report appears in the "Overdue" section of the Admin Dashboard.

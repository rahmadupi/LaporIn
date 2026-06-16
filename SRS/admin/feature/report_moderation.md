# Report Moderation & Mapping (Laporan & Peta)

## 1. Overview

The Report Moderation module is the core workflow for City Officials. It allows Admins to view incoming public infrastructure reports, filter them geographically or by urgency, and update their lifecycle status from `PENDING` to either `IN REVIEW`, `REJECTED`, or transition them to the Dispatch phase. It also includes an interactive map view for spatial analysis.

## 2. Traceability

- **FRs Covered:** ADM-002, ADM-003, ADM-004, ADM-009, ADM-010, ADM-017
- **Business Rules:** BR-ADM-001 (Presentation Anonymity: True reporter ID is hidden in UI if `isAnonymous == true`, but retained in Firestore).

## 3. UI/UX Requirements

- **Laporan List:** A list/grid view of reports. Includes sort/filter by Status, Urgency, Anonymity, and Geohash Radius (Provinsi, Kota, Desa).
- **Appeals List:** Separate tab/section showing reports with `appealRequested == true`. Badge count shows pending appeals.
- **Map View (Peta):** Interactive map rendering report coordinates. Map pins are color-coded based on `status` (Red = Pending, Yellow = In Review, Green = Resolved). Clicking a pin opens a bottom sheet or dialog with quick actions.
- **Detail View:** Shows full image, description, rejectComment (if rejected), and status.
- **Reject Popup:** Text input field for `rejectComment` (required). Optional: select `duplicateOfId`.
- **Action Buttons:**
  - `Accept`: Changes status to `In Review`. Once clicked, this button transforms into a `Dispatch` button leading to the Dispatch Form.
  - `Reject`: Opens popup to input rejectComment. Changes status to `Rejected`, sets `rejectComment` field.

## 4. Database Interactions (Data Layer)

- **Target Collection:** `/reports/{reportId}`
- **Input (Accept):** `{ "status": "in_review", "updatedAt": "Timestamp" }`
- **Input (Reject):** `{ "status": "rejected", "rejectComment": "String", "duplicateOfId": "String?", "appealRequested": false, "updatedAt": "Timestamp" }`
- **Input (Accept Appeal):** `{ "status": "in_review", "rejectComment": null, "appealRequested": false, "appealReason": null, "appealAt": null, "updatedAt": "Timestamp" }`
- **Input (Reject Appeal Permanently):** `{ "appealRequested": false, "updatedAt": "Timestamp" }` (locks the appeal)
- **Query (Appeals List):** `where("appealRequested", "==", true)`
- **Expected Output:** Document is updated. Triggers Cloud Function to send FCM notification to the Citizen notifying them of the status change.

## 5. Acceptance Criteria

- **Scenario 1: Accepting a Pending Report**
  - **Given** the Admin is on the Report Detail page with a `pending` report.
  - **When** the Admin clicks "Accept".
  - **Then** the Firestore document status updates to `in_review`.
  - **And** the UI button dynamically changes to "Dispatch".
- **Scenario 2: Rejecting a Report**
  - **Given** the Admin clicks "Reject" on a report.
  - **When** the Admin fills in rejectComment and confirms.
  - **Then** status changes to `rejected`, `rejectComment` is saved.
  - **And** Citizen receives FCM notification with rejectComment.
- **Scenario 3: Viewing Appeals**
  - **Given** a citizen appealed a rejected report.
  - **When** Admin opens Appeals section.
  - **Then** Report appears with rejectComment shown as context, appealReason displayed.
- **Scenario 4: Accepting Appeal**
  - **Given** Admin reviews an appeal and clicks "Accept Appeal".
  - **When** the Admin confirms.
  - **Then** status changes to `in_review`, `appealRequested` becomes `false`.
  - **And** report returns to normal workflow.
- **Scenario 5: Anonymity Rule**
  - **Given** a report where `isAnonymous` is `true`.
  - **When** the Admin views the report list or details.
  - **Then** the reporter's name and avatar must display as "Warga Anonim".
  - **But** the `reporterId` must remain intact in the database payload.

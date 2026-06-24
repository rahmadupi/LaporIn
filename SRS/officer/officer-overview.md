# Officer (Petugas Lapangan) Overview

## 1. Overview

The Officer (Petugas Lapangan) is a field officer role responsible for carrying out infrastructure repair assignments dispatched by the Admin. Officers can self-request to be assigned to reports, update report status, upload completion evidence, and manage their own profile.

> **Important:** Officer accounts require **admin approval** before they can log in. See `register_page.md` for the registration flow and `user_moderation.md` for the approval process.

## 2. Feature Overview

### 2.1 Authentication

- **Login:** Email/password authentication via Firebase Auth.
- **Pre-login Check:** Upon successful Firebase Auth login, the app checks `status` in Firestore. If `"pending"`, the officer is shown an "awaiting approval" message and denied access to the workspace. If `"banned"`, they are denied with a "akun diblokir" message.
- **Forgot Password:** Reset via `FirebaseAuth.instance.sendPasswordResetEmail()` — accessible from Login page.

### 2.2 Dispatch Assignment (From Admin)

- Admin assigns a report to the officer via the Dispatch workflow (see `dispatch_workflow.md`).
- Officer receives an **FCM push notification** with report title and location.
- The assigned report appears in the officer's **Active Jobs** list.

### 2.3 Officer Self-Request (Ajuan Diri)

- Officers can **voluntarily request** to handle a specific report they see in the report list (not yet assigned to anyone).
- **Trigger:** On a report detail screen, a button "Saya Ingin Menangani Laporan Ini" (Request Dispatch).
- **Action:** Creates `/reports/{reportId}/officer/{officerId}` with `status: "requested"`.
- **Admin View:** Request appears in **Admin Petugas → Permintaan Tugas** for admin to accept or reject.
- **Accept:** Admin opens a Dispatch Form with officer **pre-filled** from the request.
- **Reject:** Officer receives email notification of rejection (with reason).

### 2.4 Active Jobs List

- List of all reports currently assigned to the officer (`dispatched` or `in_progress` status).
- Each card shows: report title, location, assigned date, current status, urgency level.
- Tap to open **Report Detail** with action buttons based on status.

### 2.5 Report Action (Update Status)

From the Report Detail screen, the officer can:

- **"Mulai Pengerjaan" (Start Work):** Changes status from `dispatched` → `in_progress`. Uploads start timestamp.
- **"Unggah Bukti" (Upload Evidence):** Camera/gallery picker to upload completion photo.
- **"Selesaikan" (Complete):** Changes status from `in_progress` → `resolved` (pending admin validation). Officer adds description of work done.
- **"Tolak Tugas" (Reject Assignment):** Officer rejects the dispatch → status returns to `in_review`, admin notified.

### 2.6 Report History

- Past reports that were assigned to and completed by the officer.
- Filter by status (completed, rejected).
- Search by title.

### 2.7 Profile & Settings

- View/edit display name, phone number, profile photo.
- Toggle `isAvailable` (available/busy) — visible to admin in Officer Directory.
- Change password (via Forgot Password flow, or in-profile if already logged in).
- Logout.

### 2.8 Notifications

- FCM push notifications for:
  - New dispatch assignment from admin
  - Report reassignment
  - Report completion validated by admin (status → resolved)
  - Report rejected by admin

## 3. Traceability

| FR      | Description                        |
| ------- | ---------------------------------- |
| ADM-005 | Admin dispatches officer           |
| ADM-011 | Admin views officer self-requests  |
| ADM-012 | Admin accepts officer self-request |
| ADM-013 | Admin rejects officer self-request |
| ADM-014 | Admin views officer directory      |
| ADM-015 | Admin manages officer schedule     |
| FR-005  | Officer updates report status      |

## 4. Security Rules

| Action                           | Officer | Admin | Citizen |
| -------------------------------- | ------- | ----- | ------- |
| View all reports                 | ❌      | ✅    | ❌      |
| View assigned reports only       | ✅      | ✅    | ❌      |
| Request to handle a report       | ✅      | ❌    | ❌      |
| Update status of assigned report | ✅      | ❌    | ❌      |
| Upload completion evidence       | ✅      | ❌    | ❌      |
| View officer directory           | ❌      | ✅    | ❌      |
| Dispatch officer                 | ❌      | ✅    | ❌      |

## 5. Acceptance Criteria

### Scenario 1: Officer Login Before Approval

- **Given** an officer registered but has not been approved by admin.
- **When** they attempt to log in.
- **Then** Firebase Auth succeeds but `status: "pending"` is detected.
- **And** the officer sees: _"Akun Anda belum disetujui Admin."_
- **And** they cannot access the officer workspace.

### Scenario 2: Officer Self-Request

- **Given** an officer is browsing the report list and finds an unassigned report.
- **When** they tap "Saya Ingin Menangani Laporan Ini".
- **Then** a request document is created at `/reports/{reportId}/officer/{officerId}`.
- **And** the button changes to "Menunggu Persetujuan Admin".
- **When** Admin approves the request.
- **Then** the officer receives an FCM notification.
- **And** the report appears in the officer's Active Jobs list.

### Scenario 3: Officer Updates Report Status

- **Given** an officer has an active dispatch (status: `dispatched`).
- **When** they tap "Mulai Pengerjaan" and confirm.
- **Then** the report status changes to `in_progress`.
- **And** the admin receives an FCM notification.
- **And** the timeline in report detail shows "Pengerjaan dimulai: [timestamp]".

# Report Status Management (Manajemen Status Laporan)

## 1. Overview

The Report Status Management module allows **Admins** (all statuses) and **Officers** (only on reports assigned to them) to change the lifecycle status of a report directly from the [Report Detail Page](./report_detail_page.md) via a status dropdown.

The dropdown sits beside the status badge on the Detail page and complements the **Accept** button on `pending` reports (which is a quick path that also opens the Dispatch Form — see [`report_moderation.md`](./report_moderation.md) Section 3.4).

**Visibility:**

| Role    | Sees dropdown? | Constraint                                                                       |
| ------- | -------------- | -------------------------------------------------------------------------------- |
| Admin   | Yes            | All reports.                                                                     |
| Officer | Yes            | Only reports where `assignedOfficerId == currentUid`. **Same options as Admin.** |
| Citizen | No             | —                                                                                |

## 2. Traceability

- **FRs Covered:** ADM-003, ADM-004, ADM-005, ADM-006, ADM-017, OFC-005, OFC-007, OFC-008
- **Related Modules:**
  - [`report_detail_page.md`](./report_detail_page.md) — where the dropdown is rendered
  - [`report_moderation.md`](./report_moderation.md) — inline Accept/Reject on the list, plus the Laporan/Pengguna Moderation shell
  - [`dispatch_workflow.md`](./dispatch_workflow.md) — opened when transitioning to `dispatched`
  - [`notification_center.md`](./notification_center.md) — citizen FCM notification on status change
- **Business Rules:**
  - BR-ADM-001 (Anonymity)
  - BR-ADM-002 (Status Transition Validation)
  - BR-ADM-003 (Audit Logging)

## 3. UI/UX Requirements

### 3.1 Dropdown Location

The status dropdown is rendered on the **Report Detail Page**, in the title block beside the status badge:

```
Jalan Rusak                          [● Menunggu Verif. ▼]
LPR-2026-2553449 • 25 Jun 2026, 03:02
```

- Tapping the badge OR the `▼` opens a **bottom sheet menu** with valid next statuses.
- For each option: status label (Bahasa Indonesia), icon, brief description.

### 3.2 Status Colors & Labels

The 5 main statuses map to the **Status Roadmap** in [report_detail_page.md](./report_detail_page.md) Section 3.2:

| Status        | Color               | Indonesian Label      | Roadmap node                                        |
| ------------- | ------------------- | --------------------- | --------------------------------------------------- |
| `pending`     | 🟠 Orange (#F59E0B) | "Menunggu Verifikasi" | 1 — Laporan Terkirim                                |
| `in_review`   | 🔵 Blue (#3B82F6)   | "Verifikasi"          | 2 — Verifikasi (Sedang berlangsung)                 |
| `dispatched`  | 🟣 Purple (#8B5CF6) | "Penugasan"           | 3 — Penugasan                                       |
| `in_progress` | 🟡 Yellow (#EAB308) | "Pengerjaan"          | 4 — Pengerjaan                                      |
| `resolved`    | 🟢 Green (#10B981)  | "Selesai"             | 5 — Selesai                                         |
| `rejected`    | 🔴 Red (#EF4444)    | "Ditolak"             | (replaces roadmap — see Section 3.2 of detail page) |

### 3.3 Valid Status Transitions (State Machine)

```
pending ──> in_review ──> dispatched ──> in_progress ──> resolved
   │           │              │              │
   │           │              │              │
   └──> rejected <────────────┴──────────────┘
            │
            └──> in_review (admin re-open only)
```

**Detailed rules:**

- From `pending`: → `in_review`, `rejected`
- From `in_review`: → `dispatched`, `rejected`
- From `dispatched`: → `in_progress`, `in_review` (un-dispatch, admin only)
- From `in_progress`: → `resolved`, `dispatched` (re-dispatch)
- From `resolved`: terminal (no transitions)
- From `rejected`: → `in_review` (admin re-open only)

### 3.4 Required Comments / Actions

- **`rejected`**: Requires `rejectComment` (mandatory, min 10 chars).
- **`dispatched`**: Triggers the **Dispatch Form** (officer picker) — must select an officer before status commits. See [`dispatch_workflow.md`](./dispatch_workflow.md).
- **`resolved`**: Optional `resolutionNotes`. Officer typically goes through the Proof Upload flow first (see [`officer/feature/officer_proof.md`](../../officer/feature/officer_proof.md)); the dropdown is the secondary path.
- **All other transitions:** No comment required.

### 3.5 Cancellation

- Tapping outside the bottom sheet OR pressing `Batal` closes it without writing.

## 4. Database Interactions (Data Layer)

### 4.1 Target Collection

`/reports/{reportId}`

### 4.2 Input Schema

```json
{
  "status": "in_review | dispatched | in_progress | resolved | rejected",
  "rejectComment": "String?", // Required if status = rejected
  "resolutionNotes": "String?", // Optional if status = resolved
  "updatedAt": "Timestamp"
}
```

For transitions into `dispatched`, an additional `/dispatches/{dispatchId}` document is created (see [`dispatch_workflow.md`](./dispatch_workflow.md)).

### 4.3 Audit Logging

Every status change MUST be logged in `/audit_logs/{logId}`:

```json
{
  "logId": "log_auto_generated",
  "adminId": "user_xyz123",
  "action": "UPDATE_REPORT_STATUS",
  "targetId": "rep_987abc",
  "details": {
    "previousState": "pending",
    "newState": "in_review",
    "comment": "String?"
  },
  "timestamp": "Timestamp"
}
```

### 4.4 Expected Output

- Report document status field is updated.
- `updatedAt` field is set to server timestamp.
- Audit log entry is created.
- Cloud Function triggers FCM notification to the Citizen (per [`notification_center.md`](./notification_center.md)).

## 5. Acceptance Criteria

### Scenario 1: Quick Status Update (Admin)

- **Given** Admin is on Report Detail page with `status = "pending"`.
- **When** Admin taps the status badge and selects "Verifikasi".
- **Then** Report status changes to `in_review`.
- **And** Audit log is created.
- **And** Citizen receives FCM notification.

### Scenario 2: Reject with Comment

- **Given** Admin is on Report Detail page with `status = "in_review"`.
- **When** Admin taps status badge and selects "Ditolak".
- **Then** A dialog appears requiring `rejectComment`.
- **And** After submitting, status changes to `rejected` and `rejectComment` is saved.
- **And** Citizen receives FCM notification with the rejection reason.

### Scenario 3: Transition to Dispatched opens Dispatch Form

- **Given** Admin is on Report Detail page with `status = "in_review"`.
- **When** Admin selects "Penugasan" from the dropdown.
- **Then** the **Dispatch Form** opens (officer picker) before the status is committed.
- **And** on confirm, `/dispatches/{dispatchId}` is created and `status = "dispatched"`.

### Scenario 4: Officer Updates In-progress → Resolved

- **Given** Officer assigned to a report with `status = "in_progress"`.
- **When** Officer taps the dropdown and selects "Selesai".
- **Then** `status` updates to `resolved` (and `proofUrl` was already set via Proof Upload).
- **And** Admin receives FCM (NOTIF-002).
- **And** the Status Roadmap highlights node 5.

### Scenario 5: Invalid Transition Blocked

- **Given** Report has `status = "resolved"`.
- **When** Admin taps the status badge.
- **Then** No transition options are shown (terminal state).
- **And** A message "Status tidak dapat diubah" is displayed.

### Scenario 6: Cancel Without Saving

- **Given** Admin opens the status dropdown.
- **When** Admin taps "Batal" or dismisses the bottom sheet.
- **Then** No changes are made to the report.
- **And** Dropdown closes without error.

## 6. Future Enhancements (Out of Scope)

- Bulk status update for multiple reports.
- Custom status names per category.
- Automated status transitions (e.g., auto-close after 30 days).

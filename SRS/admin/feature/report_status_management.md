# Report Status Management (Manajemen Status Laporan)

## 1. Overview

The Report Status Management module allows **Admins** to change the lifecycle status of a report directly from the Report Detail page via a dropdown selector. This complements the existing Report Moderation workflow (which uses Accept/Reject buttons) by providing a **quick, flexible way** to transition a report through its lifecycle stages.

**Key Difference from Report Moderation:**

- `report_moderation.md` → Accept/Reject buttons (initial review)
- `report_status_management.md` → Dropdown to change status (any lifecycle stage)

## 2. Traceability

- **FRs Covered:** ADM-003, ADM-004, ADM-005, ADM-006, ADM-017
- **Related Modules:**
  - `report_moderation.md` (initial Accept/Reject)
  - `dispatch_workflow.md` (officer assignment)
  - `notification_center.md` (citizen FCM notification on status change)
- **Business Rules:**
  - BR-ADM-001 (Anonymity)
  - BR-ADM-002 (Status Transition Validation)
  - BR-ADM-003 (Audit Logging)

## 3. UI/UX Requirements

### 3.1 Status Dropdown Location

The status dropdown is displayed on the **Report Detail page**, positioned:

- Top-right corner of the page (above the report image)
- Visible on both mobile and tablet layouts
- Color-coded based on current status (see Section 3.3)

### 3.2 Dropdown Behavior

- **Trigger:** Tap on the status badge → opens a bottom sheet menu
- **Options shown:** Only valid next statuses (state machine validation)
- **Each option shows:**
  - Status label (in Bahasa Indonesia)
  - Status icon
  - Brief description of the action
- **Confirmation:** Some transitions require a confirmation dialog (e.g., REJECTED needs a reason)

### 3.3 Status Colors & Labels

| Status        | Color               | Indonesian Label    | Description              |
| ------------- | ------------------- | ------------------- | ------------------------ |
| `pending`     | 🟠 Orange (#F59E0B) | "Menunggu Review"   | Laporan baru masuk       |
| `in_review`   | 🔵 Blue (#3B82F6)   | "Sedang Ditinjau"   | Admin sedang review      |
| `dispatched`  | 🟣 Purple (#8B5CF6) | "Sudah Didisposisi" | Petugas sudah ditugaskan |
| `in_progress` | 🟡 Yellow (#EAB308) | "Sedang Dikerjakan" | Petugas di lapangan      |
| `resolved`    | 🟢 Green (#10B981)  | "Selesai"           | Laporan selesai          |
| `rejected`    | 🔴 Red (#EF4444)    | "Ditolak"           | Laporan tidak valid      |

### 3.4 Valid Status Transitions (State Machine)

```
pending ──> in_review ──> dispatched ──> in_progress ──> resolved
   │           │              │              │
   │           │              │              │
   └──> rejected <────────────┴──────────────┘
            │
            └──> in_review (jika appeal diterima)
```

**Detailed rules:**

- From `pending`: → `in_review`, `rejected`
- From `in_review`: → `dispatched`, `rejected`
- From `dispatched`: → `in_progress`, `in_review` (un-dispatch)
- From `in_progress`: → `resolved`, `dispatched` (re-dispatch)
- From `resolved`: (terminal, no transitions)
- From `rejected`: → `in_review` (only via appeal acceptance)

### 3.5 Required Comments for Certain Transitions

- **`rejected`**: Requires `rejectComment` (mandatory)
- **`resolved`**: Optional `resolutionNotes` (recommended)
- **All other transitions**: No comment required

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

- Report document status field is updated
- `updatedAt` field is set to server timestamp
- Audit log entry is created
- Cloud Function triggers FCM notification to the Citizen (per `notification_center.md`)

## 5. Acceptance Criteria

### Scenario 1: Quick Status Update

- **Given** Admin is on Report Detail page with status = `pending`
- **When** Admin taps the status badge and selects "Sedang Ditinjau"
- **Then** Report status changes to `in_review`
- **And** Audit log is created
- **And** Citizen receives FCM notification

### Scenario 2: Reject with Comment

- **Given** Admin is on Report Detail page with status = `in_review`
- **When** Admin taps status badge and selects "Ditolak"
- **Then** A dialog appears requiring `rejectComment`
- **And** After submitting, status changes to `rejected` and `rejectComment` is saved
- **And** Citizen receives FCM notification with the rejection reason

### Scenario 3: Mark as Resolved

- **Given** Admin is on Report Detail page with status = `in_progress`
- **When** Admin taps status badge and selects "Selesai"
- **Then** Status changes to `resolved`
- **And** Optional `resolutionNotes` can be added
- **And** Status badge color changes to green

### Scenario 4: Invalid Transition Blocked

- **Given** Admin is on Report Detail page with status = `resolved`
- **When** Admin taps the status badge
- **Then** No transition options are shown (terminal state)
- **And** A message "Status tidak dapat diubah" is displayed

### Scenario 5: Cancel Without Saving

- **Given** Admin opens the status dropdown
- **When** Admin taps "Cancel" or dismisses the bottom sheet
- **Then** No changes are made to the report
- **And** Dropdown closes without error

## 6. Future Enhancements (Out of Scope)

- Bulk status update for multiple reports
- Status history timeline view
- Custom status names per category
- Automated status transitions (e.g., auto-close after 30 days)

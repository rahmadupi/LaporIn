# Report Detail Page (Detail Laporan)

> **Shared across all roles.** This is the single canonical Detail page for a report. Each role sees the same core layout but with **role-specific action affordances** described in Section 4.

## 1. Overview

The Report Detail page renders the full information of a single report — hero image, metadata, location, description, **status roadmap**, and the **Penyelesaian** (resolution evidence) section. It is reached by:

- **Admin / Officer:** tapping a row in their respective report list (Moderation → Laporan list, or Officer → assigned tasks).
- **Citizen:** tapping a row in `Riwayat Laporan` (see [`citizen/feature/citizen_history.md`](../../citizen/feature/citizen_history.md)).

## 2. Traceability

- **FRs Covered:**
  - Citizen: CIT-003 (view history), CIT-005 (rejected feedback), CIT-007 (delete pending), CIT-008 (edit pending)
  - Admin: ADM-003 (reject), ADM-004 (accept), ADM-005 (dispatch), ADM-017 (audit trail via status roadmap)
  - Officer: OFC-005 (start), OFC-007 (complete), OFC-008 (reject)
- **Related Modules:**
  - [`report_status_management.md`](./report_status_management.md) — defines status dropdown semantics
  - [`dispatch_workflow.md`](./dispatch_workflow.md) — defines the Dispatch Form opened by Admin's `Terima`
  - [`officer/feature/officer_proof.md`](../../officer/feature/officer_proof.md) — uploads the evidence photo shown in `Penyelesaian`
- **Business Rules:** BR-ADM-001 (Presentation Anonymity)

## 3. UI/UX Requirements (Canonical Layout)

```
+----------------------------------------------------------+
| [<]  Detail Laporan                              [⋮]    |
+----------------------------------------------------------+
|                                                          |
|     +------------------------------------------------+   |
|     |                                                |   |
|     |            [ HERO REPORT IMAGE ]               |   |
|     |                                                |   |
|     +------------------------------------------------+   |
|                                                          |
|  Jalan Rusak                          ● Menunggu Verif.  |
|  LPR-2026-2553449 • 25 Jun 2026, 03:02                   |
|                                                          |
|  ┌────────────────────────────────────────────────────┐  |
|  | ⏳  Menunggu Verifikasi                            |  |
|  |     Laporan sedang menunggu diverifikasi admin.    |  |
|  └────────────────────────────────────────────────────┘  |
|                                                          |
|  Lokasi Kejadian                                         |
|  Jl. Keputih Makam Blk. E No.49 D, Keputih,             |
|  Kecamatan Sukolilo, Jawa Timur                          |
|  +------------------------------------------------+      |
|  |            [ GOOGLE MAPS EMBED ]                |      |
|  +------------------------------------------------+      |
|                                                          |
|  Deskripsi                                               |
|  Tidak ada deskripsi.                                    |
|                                                          |
|  Status Laporan                                          |
|   ●─────●─────○─────○─────○                              |
|   ▼     ▼                                                |
|  Lapor-  Verifi- Penuga- Penger- Selesai                 |
|  an      kasi    san     jaan                           |
|  Terki-         (cur-                                  |
|  rim   (active) rent)                                   |
|                                                          |
|  -- Penyelesaian --                                      |
|  +------------------------------------------------+      |
|  |                                                |      |
|  |     [ EVIDENCE PHOTO BY OFFICER ]              |      |
|  |     (kosong jika belum resolved)               |      |
|  |                                                |      |
|  +------------------------------------------------+      |
|                                                          |
+----------------------------------------------------------+
|  [ Tolak ]                    [ Terima ]    <- per role  |
+----------------------------------------------------------+
```

### 3.1 Component Breakdown

| #   | Component                 | Notes                                                                                           |
| --- | ------------------------- | ----------------------------------------------------------------------------------------------- |
| 1   | **AppBar**                | Back arrow + title "Detail Laporan". Trailing `⋮` opens overflow (e.g. share, copy ID).         |
| 2   | **Hero image**            | `imageUrl` from Firestore, 16:9, full-width. Tappable to open full-screen viewer.               |
| 3   | **Title + ticket + date** | `title` (bold) and `reportId` (e.g. `LPR-2026-2553449`) + relative creation date.               |
| 4   | **Status badge**          | Top-right of title block, color-coded per current status.                                       |
| 5   | **Status callout card**   | Orange-bordered card: "Menunggu Verifikasi — Laporan sedang menunggu diverifikasi admin."       |
| 6   | **Lokasi Kejadian**       | Full reverse-geocoded address text + embedded Google Map showing the report pin.                |
| 7   | **Deskripsi**             | `description` from Firestore. Shows "Tidak ada deskripsi." when empty.                          |
| 8   | **Status Laporan**        | **Status Roadmap** — vertical timeline (mobile) showing the 5 lifecycle stages.                 |
| 9   | **Penyelesaian**          | Evidence photo uploaded by officer. Visible to **all roles**. Empty placeholder until resolved. |
| 10  | **Bottom action bar**     | Role-specific (see Section 4).                                                                  |

### 3.2 Status Roadmap (Component 8)

A **vertical timeline** with 5 nodes. The current stage is highlighted; completed stages show ✓ in blue; upcoming stages are grey.

| Stage | Internal status | Indonesian label | Description                        |
| ----- | --------------- | ---------------- | ---------------------------------- |
| 1     | `pending`       | Laporan Terkirim | "Laporan diterima sistem"          |
| 2     | `in_review`     | Verifikasi       | "Sedang berlangsung" (when active) |
| 3     | `dispatched`    | Penugasan        | "Laporan ditugaskan ke petugas"    |
| 4     | `in_progress`   | Pengerjaan       | "Petugas memperbaiki kerusakan"    |
| 5     | `resolved`      | Selesai          | "Perbaikan selesai & divalidasi"   |

If `status == "rejected"`, the roadmap is replaced by a **single red banner**: "Laporan ditolak — [rejectComment]".

### 3.3 Penyelesaian (Component 9)

- Visible to **all roles** (Admin, Officer, Citizen).
- Contains a single image: `proofUrl` set by the officer when they mark the task as resolved (see [`officer/feature/officer_proof.md`](../../officer/feature/officer_proof.md)).
- Until `status == "resolved"`, the section shows a placeholder: _"Belum ada bukti penyelesaian."_

## 4. Role-Specific Affordances

### 4.1 Admin (only role with a bottom action bar)

- **Status Dropdown:** Tap status badge (or its `▼` indicator) → bottom sheet with **all valid next statuses** (see [`report_status_management.md`](./report_status_management.md) Section 3.4). `resolved` and `rejected` are terminal except for `rejected → in_review` (re-open by admin only).
- **Bottom action bar — depends on current status:**

  | Current `status` | Bottom buttons                 | Behavior                                                                                                                                                                     |
  | ---------------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
  | `pending`        | `[ Tolak ]   [ Terima ]`       | `Tolak` → Reject Dialog (`rejectComment` required). `Terima` → sets `status = "in_review"` + opens **Dispatch Form** (officer picker).                                       |
  | `in_review`      | `[ Stop ]   [ Redispatch ]`    | `Stop` → cancel review (sets `status = "rejected"` with `rejectComment = "Stopped by admin"`). `Redispatch` → opens **Dispatch Form** directly (status remains `in_review`). |
  | `dispatched`     | `[ Stop ]   [ Redispatch ]`    | `Stop` → revert to `in_review` (un-assign). `Redispatch` → opens **Dispatch Form** to pick a different officer (overwrite `/dispatches/{dispatchId}`).                       |
  | `in_progress`    | `[ Stop ]   [ Redispatch ]`    | `Stop` → revert to `in_review` (officer receives FCM). `Redispatch` → opens Dispatch Form to pick a different officer.                                                       |
  | `resolved`       | `[ Tolak ]   [ Terima ]`       | `Tolak` → revert to `in_progress` **AND** re-dispatch to the **same officer** who originally resolved it (auto-fill officer picker). `Terima` → finalize/close (terminal).   |
  | `rejected`       | (no bottom bar; dropdown only) | —                                                                                                                                                                            |

### 4.2 Officer (assigned reports only)

- **Visible only for reports where `assignedOfficerId == currentOfficerUid`.**
- **Status Dropdown:** **Same dropdown options as Admin** (see [`report_status_management.md`](./report_status_management.md) Section 3.4). Officer can transition between any valid status (e.g. `dispatched → in_progress`, `in_progress → resolved`).
- **No bottom action bar** — all actions go through the dropdown (and the separate Proof Upload flow per [`officer/feature/officer_proof.md`](../../officer/feature/officer_proof.md)).

### 4.3 Citizen

- **No status dropdown.**
- **No bottom action bar.**
- `Edit Deskripsi` and `Hapus` (soft delete) are reachable only via the citizen's `Riwayat Laporan` long-press menu (see [`citizen/feature/citizen_history.md`](../../citizen/feature/citizen_history.md) Section 3.4) — **not** rendered on the Detail page.
- **Read-only** view of the Detail page.

## 5. Database Interactions

- **Read:** `firestore.collection('reports').doc(reportId).snapshots()`.
- **Update (Admin dropdown):** `update({ status, rejectComment?, resolutionNotes?, updatedAt })` — see [`report_status_management.md`](./report_status_management.md) Section 4.
- **Update (Admin Terima on pending):** `update({ status: "in_review", updatedAt })` → push Dispatch Form → on confirm, write `/dispatches/{dispatchId}` and `update({ status: "dispatched" })`.
- **Update (Admin Stop on in_review / dispatched / in_progress):** revert `status` to the previous state, set `rejectComment: "Stopped by admin"`, FCM to assigned officer.
- **Update (Admin Redispatch):** open Dispatch Form → on confirm, **overwrite** the existing `/dispatches/{dispatchId}` (or create a new one) with the new `officerId`, `status = "dispatched"`, FCM to both old and new officer.
- **Update (Admin Tolak on resolved):** `update({ status: "in_progress", updatedAt })` + Dispatch Form pre-filled with the original `assignedOfficerId` (locked) → on confirm, write a new `/dispatches/{dispatchId}` for the same officer.
- **Update (Admin Terima on resolved):** write finalization: `update({ status: "verified", verifiedBy: adminUid, verifiedAt: serverTimestamp(), updatedAt })` (or simply leave as `resolved` and add a `verifiedAt` field — see note in [`report_status_management.md`](./report_status_management.md)).
- **Update (Officer dropdown):** per [`report_status_management.md`](./report_status_management.md) Section 4 — same write shape as Admin.
- **Update (Citizen):** no actions on this page; `Edit Deskripsi` / `Hapus` live in the Riwayat Laporan long-press menu.
- **Audit log:** every status change writes to `/audit_logs/{logId}` per [`report_status_management.md`](./report_status_management.md) Section 4.3.
- **Expected Output:** Real-time updates to the page (stream listener); FCM to the citizen and officer on each status change (per [`notification_center.md`](./notification_center.md)).

## 6. Acceptance Criteria

### Scenario 1: Status Roadmap reflects current state

- **Given** a report with `status = "in_review"`.
- **When** Admin opens the Detail page.
- **Then** node 1 (Laporan Terkirim) is marked ✓ and node 2 (Verifikasi) is highlighted as current.
- **And** nodes 3-5 are greyed out.

### Scenario 2: Admin Terima opens Dispatch Form

- **Given** Admin is on a `pending` report.
- **When** Admin taps `Terima`.
- **Then** `status` updates to `in_review`.
- **And** the **Dispatch Form** is pushed onto the navigation stack.

### Scenario 3: Admin Stop on an in-progress report reverts to in_review

- **Given** Admin is on an `in_progress` report.
- **When** Admin taps `Stop`.
- **Then** `status` reverts to `in_review`.
- **And** the assigned officer receives an FCM notification.

### Scenario 4: Admin Redispatch reassigns officer

- **Given** Admin is on a `dispatched` report.
- **When** Admin taps `Redispatch`.
- **Then** the **Dispatch Form** opens, pre-filled with the report context but with the officer field editable.
- **And** on confirm, `/dispatches/{dispatchId}` is updated with the new officer and the previous officer receives FCM "task re-assigned".

### Scenario 5: Admin Tolak on a resolved report re-dispatches to the SAME officer

- **Given** Admin is on a `resolved` report with `assignedOfficerId = "off_456"`.
- **When** Admin taps `Tolak`.
- **Then** `status` reverts to `in_progress`.
- **And** the Dispatch Form opens with officer pre-filled and locked to `"off_456"` (cannot be changed).
- **And** officer `"off_456"` receives FCM "resolution rejected, please redo".

### Scenario 6: Admin Terima on a resolved report finalizes the report

- **Given** Admin is on a `resolved` report.
- **When** Admin taps `Terima`.
- **Then** the report is marked as **verified/closed** (terminal).
- **And** the citizen receives FCM "Laporan selesai & diverifikasi".

### Scenario 7: Penyelesaian hidden until resolved

- **Given** a report with `status = "in_progress"`.
- **When** any role opens the Detail page.
- **Then** the `Penyelesaian` section shows the placeholder "Belum ada bukti penyelesaian."
- **When** officer uploads proof + completes task → `status = "resolved"`.
- **Then** the next render shows the evidence photo in `Penyelesaian`.

### Scenario 8: Officer can update status via dropdown (same as Admin)

- **Given** Officer assigned to a `dispatched` report.
- **When** Officer opens the dropdown.
- **Then** valid options are the same as Admin would see: `in_progress`, `rejected`.
- **And** selecting `in_progress` updates the doc and refreshes the roadmap.

### Scenario 9: Rejected report shows banner instead of roadmap

- **Given** a report with `status = "rejected"` and a non-empty `rejectComment`.
- **When** Admin opens the Detail page.
- **Then** the Status Roadmap is replaced by a red banner containing the reject reason.
- **And** the dropdown shows `in_review` as the only valid next status (re-open).

### Scenario 10: Anonymity on detail page

- **Given** a report where `isAnonymous == true`.
- **When** Admin opens the Detail page.
- **Then** the reporter's name displays as "Warga Anonim".
- **And** the Firestore `reporterId` is preserved.

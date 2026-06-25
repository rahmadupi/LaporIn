# Report Moderation (Laporan & Pengguna)

## 1. Overview

The Report Moderation module is the **entry point for City Officials** to triage incoming public infrastructure reports. The Moderation page is split into **two sub-pages** accessible via a tab switcher:

| Tab        | Purpose                                                               | Linked Spec                                  |
| :--------- | :-------------------------------------------------------------------- | :------------------------------------------- |
| `Laporan`  | Detailed list of citizen reports with inline moderation actions       | This document (Section 3.1)                  |
| `Pengguna` | User ban / unban queue, dormant account management, officer approvals | [`user_moderation.md`](./user_moderation.md) |

> **Removed (out of scope):** Appeals/Banding workflow and the public comment system have been removed. Status changes are handled exclusively via the dropdown on the Detail page — see [`report_status_management.md`](./report_status_management.md) and [`report_detail_page.md`](./report_detail_page.md).

## 2. Traceability

- **FRs Covered:** ADM-002, ADM-003, ADM-004, ADM-009, ADM-010, ADM-017
- **Business Rules:** BR-ADM-001 (Presentation Anonymity — true reporter ID hidden when `isAnonymous == true`, but retained in Firestore).

## 3. UI/UX Requirements

### 3.1 Moderation Page Shell

```
+----------------------------------------------------------+
|  Moderasi                              [🔍] [⚙]           |
+----------------------------------------------------------+
|  ┌─────────────┐  ┌─────────────┐                        |
|  │  Laporan    │  │  Pengguna   │   <- tab switcher      |
|  └─────────────┘  └─────────────┘                        |
+----------------------------------------------------------+
```

- **Top-level navigation:** `BottomNavigationBar` within Admin shell contains `Beranda`, `Moderasi`, `Peta`, `Profil`. The `Moderasi` tab opens the Moderation shell above.
- **Tab switcher:** Two pill-shaped tabs. Default = `Laporan`.

### 3.2 Laporan Sub-Page (Detailed List)

The Laporan sub-page is a **detailed, roomy list** — each row is large enough to display the full report summary plus **inline Accept / Reject buttons when the report is `pending`**. The goal is that the admin can triage a queue without opening each detail page first.

**Filter chips (horizontal scroll):**

`Semua` · `Menunggu` (`pending`) · `Diproses` (`in_review` + `dispatched` + `in_progress`) · `Selesai` (`resolved`) · `Ditolak` (`rejected`)

**Sort/filter dropdowns:** Status (auto), Urgency (`Rendah | Biasa | Tinggi | Darurat`), Anonymity (`Semua | Anonim | Publik`), Geohash Radius (Provinsi, Kota, Desa).

**List Item Layout** (each row is at least 140 dp tall):

```
+----------------------------------------------------------+
| [thumbnail 64x64]  Jalan Rusak di Depan Pasar            |
|                    ● Menunggu Verifikasi   TINGGI  Anonim |
|                    LPR-2026-2553449 • 24 Jun 14:32        |
|                    Jl. Merdeka, Surabaya                  |
|                                                          |
|              [ Tolak ]            [ Terima ]   <- shown  |
|                                       only when pending  |
+----------------------------------------------------------+
```

- Tap the row body (outside buttons) → navigates to [Report Detail Page](./report_detail_page.md).
- `Tolak` button → opens **Reject Dialog** (Section 3.3).
- `Terima` button → immediately sets `status = "in_review"` **AND** opens the **Dispatch Form** (officer picker — see [`dispatch_workflow.md`](./dispatch_workflow.md)). SnackBar confirms acceptance.
- For non-pending statuses, **no inline buttons** — only the row tap navigates to Detail.

**Empty state:** Illustration + "Tidak ada laporan pada filter ini."

### 3.3 Reject Dialog

Triggered by `Tolak` (either from the list row or from the Detail page bottom).

- **Reject Comment field** — multi-line text input, **required** (min 10 chars).
- **Duplicate of (optional)** — picker to select an existing report as `duplicateOfId`.
- Buttons: `Batal` (dismiss) and `Tolak Laporan` (primary, red).
- On confirm: `status → "rejected"`, `rejectComment` saved, `duplicateOfId?` saved, `updatedAt = serverTimestamp()`. FCM fires to citizen.

### 3.4 Detail Page Linkage

For full per-status actions (dropdown to advance the workflow, view `Penyelesaian`, etc.), the admin taps the row → [Report Detail Page](./report_detail_page.md), which carries:

- Hero image, ticket number, title, status badge, location map, description.
- **Status Roadmap** (5 stages) below the description — see [`report_detail_page.md`](./report_detail_page.md).
- **Bottom action bar:**
  - `pending` → `[ Tolak ]  [ Terima → Dispatch Form ]`
  - other statuses → status dropdown only (no bottom buttons)
- `Penyelesaian` section at the bottom (evidence photo once `status == "resolved"`).

## 4. Database Interactions (Data Layer)

- **Target Collection:** `/reports/{reportId}`
- **Read (Laporan list stream):** `firestore.collection('reports').orderBy('createdAt', descending: true).snapshots()` — client-side filter by chip.
- **Input (Terima — inline accept, triggers dispatch):**
  ```json
  { "status": "in_review", "updatedAt": "Timestamp" }
  ```
  Then navigation pushes the Dispatch Form (officer picker), which on confirm writes a new `/dispatches/{dispatchId}` document and sets `status = "dispatched"` (see [`dispatch_workflow.md`](./dispatch_workflow.md)).
- **Input (Tolak):**
  ```json
  {
    "status": "rejected",
    "rejectComment": "String",
    "duplicateOfId": "String?",
    "updatedAt": "Timestamp"
  }
  ```
- **Expected Output:** Document updated. Cloud Function `onUpdate` sends FCM notification to the citizen (per [`notification_center.md`](./notification_center.md)).

## 5. Acceptance Criteria

### Scenario 1: Inline Accept a Pending Report → Dispatch Form

- **Given** Admin is on the Laporan sub-page with at least one `pending` report.
- **When** Admin taps `Terima` on a row.
- **Then** Firestore `status` updates to `in_review`.
- **And** the **Dispatch Form** opens with the report context pre-filled.
- **And** after a dispatcher picks an officer, the status transitions to `dispatched` and the row visually moves out of the `Menunggu` chip.

### Scenario 2: Inline Reject a Pending Report

- **Given** Admin taps `Tolak` on a pending row.
- **When** the Reject Dialog opens and Admin submits a valid `rejectComment`.
- **Then** `status` updates to `rejected`, `rejectComment` is saved.
- **And** Citizen receives FCM notification with the rejection reason.

### Scenario 3: Non-pending row has no action buttons

- **Given** a row whose `status` is `in_review` (or later / `rejected`).
- **When** the row is rendered.
- **Then** neither `Terima` nor `Tolak` buttons are visible.
- **And** tapping the row still navigates to the Detail page.

### Scenario 4: Tab switch to Pengguna

- **Given** Admin is on the Moderation shell.
- **When** Admin taps the `Pengguna` tab.
- **Then** the Laporan list is replaced by the user management UI defined in [`user_moderation.md`](./user_moderation.md).

### Scenario 5: Anonymity Rule

- **Given** a report where `isAnonymous` is `true`.
- **When** the Admin views the Laporan list or Detail.
- **Then** the reporter's name and avatar must display as "Warga Anonim".
- **But** the `reporterId` must remain intact in the Firestore payload (BR-ADM-001).

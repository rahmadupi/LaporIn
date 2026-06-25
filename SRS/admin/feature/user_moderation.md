# User Moderation (Pengguna — Moderation Sub-Page)

## 1. Overview

The **Pengguna** sub-page lives inside the **Moderation** shell — paired with the `Laporan` sub-page (see [`report_moderation.md`](./report_moderation.md) Section 3.1). It bundles three queues for managing user accounts:

| Queue                                | `users.status` | Purpose                                                            |
| ------------------------------------ | -------------- | ------------------------------------------------------------------ |
| **Active Users (Daftar Pengguna)**   | `active`       | Search/browse active citizens & officers; **ban** abusers.         |
| **Banned Users (Pengguna Diblokir)** | `banned`       | List currently banned accounts; **unban** to restore access.       |
| **Officer Approval (Persetujuan)**   | `pending`      | Officer registrations awaiting approval; **setujui / tolak**.      |
| **Dormant Users (Akun Dormant)**     | `inActive`     | Inactive accounts; admin can **reactivate** if user is locked out. |

Each queue is reached via a secondary tab/pill inside the Pengguna shell.

## 2. Traceability

- **FRs Covered:** ADM-011, ADM-012, ADM-013, ADM-019, ADM-025, ADM-026
- **Related Modules:**
  - [`report_moderation.md`](./report_moderation.md) — paired sibling sub-page
  - [`user_profile_management.md`](./user_profile_management.md) — profile detail drill-in
  - [`register_page.md`](../../utility/register_page.md) — registration flow that produces `pending` officers
  - [`auth_session.md`](../../utility/auth_session.md) — login / dormant self-reactivation

## 3. UI/UX Requirements

### 3.1 Pengguna Shell

```
+----------------------------------------------------------+
|  Moderasi > Pengguna                  [🔍] [⚙]           |
+----------------------------------------------------------+
|  ┌────────┐ ┌────────┐ ┌────────────┐ ┌────────┐         |
|  │ Aktif  │ │ Diblokir│ │ Persetujuan│ │ Dormant│         |
|  └────────┘ └────────┘ └────────────┘ └────────┘         |
+----------------------------------------------------------+
```

- Default tab: **Aktif** (since it's the most-used).
- Search bar above the tabs filters across the active tab.

### 3.2 Aktif (Active Users)

- **Source:** `users` where `status == "active"`.
- **Card per user:** avatar, nama, email, role (Citizen/Officer), tanggal daftar, jumlah laporan / tugas aktif.
- **Per-row action:** `Ban` button (red) → opens **Ban Dialog** (Section 3.2.1).
- **Search/filter:** by name, email, role.
- Tapping the card body (outside the Ban button) opens [`user_profile_management.md`](./user_profile_management.md) detail view (read-only).

#### 3.2.1 Ban Dialog

Triggered by `Ban`.

- **Ban reason** — multi-line text input, **required** (min 10 chars).
- Buttons: `Batal` (dismiss) and `Blokir Pengguna` (primary, red).
- On confirm: `status → "banned"`, `banReason` saved, `bannedAt = serverTimestamp()`, `bannedBy = adminUid`. Cloud Function disables Firebase Auth (per ADM-019).

### 3.3 Diblokir (Banned Users)

- **Source:** `users` where `status == "banned"`.
- **Columns:** Nama, Email, Role, Ban Reason, Banned At, Banned By Admin.
- **Per-row action:** `Unban` button (primary).
- **Search/filter:** by role, date range of ban.

### 3.4 Persetujuan (Officer Approval Queue)

- **Source:** `users` where `role == "officer"` AND `status == "pending"`.
- **Columns:** Nama, Email, Nomor HP, District, Tanggal Pendaftaran.
- **Per-row actions:**
  - `Setujui` → `status: "active"`, `approvedBy`, `approvedAt`. Email sent.
  - `Tolak` → Reject Dialog (similar to Ban Dialog, requires reason). Sets `status: "banned"` with `banReason` (or deletes the doc).

### 3.5 Dormant (Akun Dormant)

- **Source:** `users` where `status == "inActive"`.
- **Columns:** Nama, Email, Role, Last Sign-In, Inactive Since.
- **Per-row action:** `Reactivate` button → sets `status: "active"`.
- **Catatan:** Dormant accounts are NOT banned — users can self-activate via the login screen's "Aktifkan Kembali" button. Admin reactivation is only when the user is locked out (e.g., lost email access).

## 4. Database Interactions (Data Layer)

- **Target Collection:** `/users`
- **Query (Aktif):** `where("status", "==", "active")`
- **Query (Diblokir):** `where("status", "==", "banned")`
- **Query (Persetujuan):** `where("role", "==", "officer")` AND `where("status", "==", "pending")`
- **Query (Dormant):** `where("status", "==", "inActive")`

### 4.1 Input Schemas

| Action                                      | Update                                                                                           |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Ban (Aktif → Diblokir)**                  | `{ "status": "banned", "banReason": reason, "bannedAt": serverTimestamp, "bannedBy": adminUid }` |
| **Unban (Diblokir → Aktif)**                | `{ "status": "active" }` (clear `banReason` / `bannedAt` / `bannedBy`)                           |
| **Approve officer (Persetujuan → Aktif)**   | `{ "status": "active", "approvedBy": adminId, "approvedAt": Timestamp }`                         |
| **Reject officer (Persetujuan → Diblokir)** | `{ "status": "banned", "banReason": reason, ... }` OR delete document                            |
| **Reactivate dormant (Dormant → Aktif)**    | `{ "status": "active" }`                                                                         |
| **User self-reactivate (login screen)**     | `{ "status": "active" }`                                                                         |

### 4.2 Expected Output

- **Ban:** Firebase Auth disabled via Cloud Function; user cannot sign in.
- **Unban:** User can sign in again. Cloud Function re-enables Auth.
- **Approve:** Officer can log in. Email notification sent.
- **Reject:** Officer account deactivated. Email rejection notice sent with reason.
- **Reactivate:** User can sign in with same credentials. History preserved.

## 5. Acceptance Criteria

### Scenario 1: Ban an Active User

- **Given** Admin is on the `Aktif` tab with at least one active user.
- **When** Admin taps `Ban`, fills `banReason`, and confirms.
- **Then** `status` updates to `banned`, `banReason` is saved.
- **And** the user disappears from the `Aktif` list and appears in `Diblokir`.
- **And** Firebase Auth is disabled (user cannot log in).

### Scenario 2: Unban a Banned User

- **Given** Admin is on the `Diblokir` tab.
- **When** Admin taps `Unban` on a user and confirms.
- **Then** `status` updates to `active` and the user moves to `Aktif`.

### Scenario 3: Approve Officer

- **Given** Admin is on `Persetujuan` tab.
- **When** Admin taps `Setujui` on a pending officer.
- **Then** `status` updates to `active` with `approvedBy` and `approvedAt`.
- **And** Officer receives email + can log in.

### Scenario 4: Reject Officer with Reason

- **Given** Admin taps `Tolak` on a pending officer.
- **When** Admin provides a reason and confirms.
- **Then** `status` updates to `banned` with `banReason`.
- **And** Firebase Auth is disabled and rejection email sent.

### Scenario 5: Admin Reactivate Dormant

- **Given** Admin is on `Dormant` tab.
- **When** Admin taps `Reactivate` on an inactive user.
- **Then** `status` updates to `active`.
- **And** user can log in again.

### Scenario 6: Tab Switch Persists State

- **Given** Admin switches from `Aktif` to `Diblokir` and back.
- **When** they return to `Aktif`.
- **Then** the search query and scroll position are preserved.

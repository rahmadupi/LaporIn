# Officer Laporan (Public Reports — Self-Request Feed)

## 1. Overview

Halaman feed yang menampilkan **semua laporan publik** yang belum di-dispatch (`pending`, `in_review`) atau yang available untuk self-request oleh Petugas Lapangan. Officer dapat melihat laporan, lalu melakukan **self-request** ("Saya Ingin Menangani Laporan Ini") untuk mengajukan diri menangani laporan tertentu.

> **Padanan:** lihat [admin/feature/report_moderation.md](../admin/feature/report_moderation.md) untuk versi admin (full moderation) dan [citizen/feature/citizen_laporan.md](./citizen_laporan.md) untuk versi citizen (read-only).

## 2. Traceability

- **FRs Covered:** OFC-003 (self-request / Ajuan Diri), OFC-015 (browse available reports).
- **Notification FR:** NOTIF-002 (setelah self-request diterima → FCM ke officer).
- **Layer:** Presentation (planned `features/officer/screens/officer_public_reports_screen.dart`).

## 3. UI/UX Requirements

### 3.1 AppBar

- Title "Laporan" (center, bold).
- **Actions (top-right):** bell icon (🔔) dengan unread badge → push ke [officer_notification.md](./officer_notification.md).

### 3.2 Filter & Search

- **Filter chips:** `Tersedia` (bisa di-request), `Sudah Diajukan` (self-request pending), kategori, urgency.
- **Search bar:** by judul laporan.

### 3.3 List Item

- Thumbnail foto laporan.
- Judul + alamat.
- **Status badge** (`pending`, `in_review` — yang available).
- **Status self-request** (jika officer sudah pernah request): `requested` / `accepted` / `rejected`.
- Urgency indicator.
- Tanggal dibuat.
- **Tap:** buka `ReportDetailScreen`.

### 3.4 Self-Request Action

Pada `ReportDetailScreen`, jika status `pending` atau `in_review` AND officer belum request:

- Tombol **"Saya Ingin Menangani Laporan Ini"** (CTA utama).
- Tap → create dokumen di `/reports/{reportId}/officer/{officerId}` dengan `status: "requested"`, `requestedAt: serverTimestamp()`.
- SnackBar: _"Ajuan terkirim. Menunggu persetujuan Admin."_

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}`, `/reports/{reportId}/officer/{officerId}` (sub-collection).
- **Read (stream):** `firestore.collection('reports').where('status', whereIn: ['pending', 'in_review']).orderBy('createdAt', descending: true).limit(50)`.
- **Self-Request (OFC-003):** `firestore.collection('reports').doc(reportId).collection('officer').doc(officerUid).set({ status: 'requested', requestedAt: serverTimestamp() })`.
- **Expected Output:** Admin melihat request di [Admin Petugas → Permintaan Tugas](../admin/feature/dispatch_workflow.md). Approve → `OfficerHomeScreen` Tugas Aktif ter-update. Reject → officer dapat email/FCM notif penolakan.

## 5. Acceptance Criteria

### Scenario 1: Browse Available Reports

- **Given** officer membuka tab Laporan.
- **When** 12 laporan `pending`/`in_review` tersedia.
- **Then** 12 item tampil dengan status `pending` atau `in_review`.

### Scenario 2: Submit Self-Request

- **Given** officer melihat laporan dengan status `pending`.
- **When** mereka tap tombol "Saya Ingin Menangani Laporan Ini".
- **Then** dokumen dibuat di `/reports/{reportId}/officer/{officerUid}` dengan `status: "requested"`.
- **And** SnackBar: "Ajuan terkirim. Menunggu persetujuan Admin."

### Scenario 3: Already Requested

- **Given** officer sudah pernah self-request laporan ini.
- **When** mereka membuka laporan yang sama lagi.
- **Then** tombol "Saya Ingin Menangani Laporan Ini" disabled dengan teks "Sudah Diajukan".

### Scenario 4: Admin Approval → Officer Notified

- **Given** officer sudah self-request, admin approve (lihat [dispatch_workflow.md](../admin/feature/dispatch_workflow.md)).
- **When** admin clicks "Terima" pada ajuan officer.
- **Then** laporan muncul di `OfficerHomeScreen` (Tugas Aktif) dengan status `dispatched`.
- **And** officer menerima FCM (NOTIF-002) — _"Anda mendapat penugasan baru."_

## 6. Cross-References

- **Admin equivalent:** [admin/feature/report_moderation.md](../admin/feature/report_moderation.md).
- **Citizen equivalent:** [citizen/feature/citizen_laporan.md](./citizen_laporan.md) (read-only).
- **Dispatch flow:** [admin/feature/dispatch_workflow.md](../admin/feature/dispatch_workflow.md) §3.1 (Self-Request Flow).
- **Active Tasks:** [officer_home.md](./officer_home.md).
- **Status enum:** [app-overview.md §3](../app-overview.md#3-alur-hidup-laporan-end-to-end-report-lifecycle).

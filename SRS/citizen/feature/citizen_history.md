# Citizen Report History (Riwayat Laporan)

## 1. Overview

Halaman yang menampilkan **seluruh laporan** yang pernah dibuat oleh warga yang sedang login — tanpa terkecuali, mencakup semua status (`pending`, `in_review`, `dispatched`, `in_progress`, `resolved`, `rejected`). Berfungsi sebagai arsip pribadi sekaligus pusat aksi (edit/hapus/appeal/rating) sesuai lifecycle status.

> **Pengganti dari spec lama:** Sebelumnya tab ini bernama "Watch Zones" (placeholder). Sesuai brief terbaru, tab ini diganti menjadi **Riwayat Laporan** — lihat [admin/feature/report_moderation.md](../admin/feature/report_moderation.md) untuk padanan admin-nya (Admin Laporan).

## 2. Traceability

- **FRs Covered:** CIT-003 (read all history), CIT-005 (appeal), CIT-007 (delete pending), CIT-008 (edit pending), CIT-009 (rating resolved).
- **Layer:** Presentation (`features/reports/presentation/screens/report_history_screen.dart`).
- **Domain entity:** `Report` di `shared_domain_data/report/domain/entities/report_entity.dart`.

## 3. UI/UX Requirements

### 3.1 AppBar

- Title "Riwayat Laporan" (center, bold).
- **Leading:** none (root tab, back dimatikan).
- **Actions (top-right):**
  - **Bell icon (🔔)** — akses [notification_page.md](./notification_page.md), dengan badge unread.
  - **Filter icon (⚙️)** — planned (saat ini filter via chip row).

### 3.2 Filter & Search Bar

- **Filter chips (horizontal scroll):** `Semua`, `Pending`, `Diproses` (`in_review` + `dispatched` + `in_progress`), `Selesai` (`resolved`), `Ditolak` (`rejected`).
- **Search bar:** Pencarian by judul laporan (client-side filter).

### 3.3 List Item (`ReportHistoryScreen`)

Tiap item menampilkan:

- **Thumbnail foto laporan** (kiri).
- **Judul laporan** (bold).
- **Status badge** — color-coded sesuai status (lihat enum [app-overview.md §3](../app-overview.md)):
  - `pending`: abu-abu
  - `in_review`: kuning
  - `dispatched` / `in_progress`: biru
  - `resolved`: hijau
  - `rejected`: merah
- **Tanggal dibuat** (relative: "2 hari lalu").
- **Indikator anonim** (jika `isAnonymous: true`).

### 3.4 Per-Item Action Menu (long-press atau swipe)

| Action             | Syarat Status         | Hasil                                                       |
| :----------------- | :-------------------- | :---------------------------------------------------------- |
| **Edit Deskripsi** | `pending`             | `update({ description })` di Firestore                      |
| **Hapus**          | `pending`             | Soft delete: `update({ isDeleted: true })`                  |
| **Banding**        | `rejected` (≤ 24 jam) | `update({ appealRequested: true, appealReason, appealAt })` |
| **Beri Rating**    | `resolved`            | Tambah dokumen di `/ratings/{ratingId}`                     |
| **Lihat Detail**   | Semua status          | Push ke `ReportDetailScreen`                                |

### 3.5 Empty State

Ilustrasi + pesan: _"Belum ada laporan. Yuk buat yang pertama!"_

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}`, `/ratings/{ratingId}`.
- **Read (default stream):** `firestore.collection('reports').where('reporterId', isEqualTo: currentUid).orderBy('createdAt', descending: true).snapshots()` — real-time, mencakup **semua status** (tidak ada filter status di query level — filtering dilakukan client-side via chip).
- **Filter (client-side):** dari stream data, filter by chip status aktif.
- **Search (client-side):** filter list by `judul contains query`.
- **Edit:** `update({ description })` saat `status == "pending"` (Security Rules guard di server-side).
- **Soft delete:** `update({ isDeleted: true })` saat `status == "pending"` (FR-2.5 di global SRS).
- **Appeal:** `update({ appealRequested: true, appealReason, appealAt })` saat `status == "rejected"` dalam 24 jam.
- **Rating:** `collection('ratings').add({ reportId, reporterId, stars, comment, createdAt })` saat `status == "resolved"`.

## 5. Acceptance Criteria

### Scenario 1: Menampilkan Semua Laporan

- **Given** warga dengan 18 laporan (5 `pending`, 4 `in_review`, 3 `dispatched`, 2 `in_progress`, 3 `resolved`, 1 `rejected`).
- **When** mereka membuka tab Riwayat.
- **Then** semua 18 laporan tampil (default filter `Semua`).
- **And** terurut dari yang terbaru (`createdAt desc`).

### Scenario 2: Filter by Status

- **When** mereka tap filter chip "Selesai".
- **Then** hanya 3 laporan `resolved` yang tampil.

### Scenario 3: Edit Window Closed

- **Given** laporan warga berstatus `in_review`.
- **When** mereka mencoba edit deskripsi.
- **Then** UI menampilkan SnackBar: _"Laporan tidak dapat diedit setelah diproses admin."_
- **And** tidak ada Firestore write yang terjadi (ditolak Security Rules).

### Scenario 4: Appeal Window

- **Given** laporan `status: "rejected"` 5 jam lalu.
- **When** mereka membuka dialog banding.
- **Then** form ditampilkan (masih dalam 24 jam).
- **And** submit → `appealRequested: true` ditulis ke Firestore.

### Scenario 5: Rating Resolved Report

- **Given** laporan `status: "resolved"`.
- **When** mereka tap "Beri Rating" + isi bintang + komentar.
- **Then** dokumen baru dibuat di `/ratings/{ratingId}`.
- **And** tampilan item ter-update (icon bintang muncul).

## 6. Cross-References

- **Admin equivalent:** [admin/feature/report_moderation.md](../admin/feature/report_moderation.md) (Admin Laporan → Report List).
- **Status enum & lifecycle:** [app-overview.md §3](../app-overview.md#3-alur-hidup-laporan-end-to-end-report-lifecycle).
- **Data model:** [data-model.md §3.2](../data-model.md) (`/reports/{reportId}` schema).
- **DDD layers:** [system-architecture.md §4](../system-architecture.md#4-class-architecture-domain-driven-design).

## Implementation Reference

- File: `lib/features/reports/presentation/screens/report_history_screen.dart`
- Route: `AppRoutes.citizenReports`
- Entity: `Report` di `shared_domain_data/report/domain/entities/`.

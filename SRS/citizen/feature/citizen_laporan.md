# Citizen Laporan (Public Reports Feed)

## 1. Overview

Halaman feed publik yang menampilkan **semua laporan** dari warga lain di area pengguna. Berbeda dari tab **Riwayat** (yang hanya menampilkan laporan milik sendiri), tab **Laporan** memungkinkan warga melihat laporan publik orang lain — untuk _social awareness_ dan transparansi. Citizen hanya bisa _read-only_ di sini; tidak ada aksi edit/delete terhadap laporan orang lain.

> **Padanan:** lihat [admin/feature/report_moderation.md](../admin/feature/report_moderation.md) untuk versi admin (full moderation rights) dan [officer/feature/officer_laporan.md](./officer_laporan.md) untuk versi officer (dengan self-request action).

## 2. Traceability

- **FRs Covered:** CIT-013 (view public reports), CIT-014 (social awareness feed).
- **Layer:** Presentation (planned `features/reports/presentation/screens/public_reports_screen.dart`).

## 3. UI/UX Requirements

### 3.1 AppBar

- Title "Laporan" (center, bold).
- **Actions (top-right):** bell icon (🔔) dengan unread badge → push ke [notification_page.md](./notification_page.md).

### 3.2 Filter & Search

- **Filter chips:** `Semua`, kategori infrastruktur (Jalan, Drainase, Penerangan, dll), urgency (Rendah/Biasa/Tinggi/Darurat), `Terdekat` (sort by distance).
- **Search bar:** by judul laporan.

### 3.3 List Item

- Thumbnail foto laporan (kiri).
- Judul laporan + alamat ringkas.
- **Badge anonim** jika `isAnonymous: true` (display: "Anonim").
- Status badge (color-coded, see [app-overview.md §3](../app-overview.md)).
- Jarak dari posisi user ("1.2 km").
- Urgency indicator.
- Tanggal dibuat (relative).
- **Tap:** buka `ReportDetailScreen` (read-only mode untuk laporan orang lain).

### 3.4 Empty State

Ilustrasi + "Belum ada laporan publik di area Anda."

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}`.
- **Read (public stream):** `firestore.collection('reports').where('status', whereIn: ['pending', 'in_review', 'dispatched', 'in_progress', 'resolved']).orderBy('createdAt', descending: true).limit(50)` — top 50 laporan terbaru.
- **Excluded:** laporan `rejected` (hidden) dan laporan milik sendiri (ditampilkan di Riwayat).
- **Geolocation:** opsional — jika user mengizinkan lokasi, filter/sort by distance via Geohash query.
- **Anonymity:** jika `isAnonymous: true`, server tetap kembalikan dokumen, tapi UI render "Anonim" untuk `displayName` (BR-CIT-001).

## 5. Acceptance Criteria

### Scenario 1: Default Feed

- **Given** warga membuka tab Laporan.
- **When** 30 laporan publik tersedia di area.
- **Then** 30 item tampil, terurut dari yang terbaru.

### Scenario 2: Filter by Kategori

- **When** mereka tap filter chip "Jalan".
- **Then** hanya laporan dengan `categoryId == "cat_roads"` yang tampil.

### Scenario 3: Anonim Display

- **Given** laporan dengan `isAnonymous: true`.
- **When** ditampilkan di feed publik.
- **Then** reporter name ditampilkan sebagai "Anonim" (BR-CIT-001).

### Scenario 4: Tap Item (Read-Only)

- **When** mereka tap item laporan orang lain.
- **Then** `ReportDetailScreen` opens dalam read-only mode (no Edit/Hapus/Banding actions available).

## 6. Cross-References

- **Admin equivalent:** [admin/feature/report_moderation.md](../admin/feature/report_moderation.md) (Admin Laporan → Report List).
- **Officer equivalent:** [officer/feature/officer_laporan.md](./officer_laporan.md) (dengan self-request action).
- **Self reports:** [citizen_history.md](./citizen_history.md) (Riwayat).
- **Status enum:** [app-overview.md §3](../app-overview.md#3-alur-hidup-laporan-end-to-end-report-lifecycle).
- **Anonymity rule:** BR-CIT-001 (lihat [citizen-overview.md §4](../citizen-overview.md)).

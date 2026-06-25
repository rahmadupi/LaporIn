# Officer Home / Active Tasks (Tugas Aktif)

## 1. Overview

Tab utama setelah officer login. Menampilkan daftar tugas (`dispatched` + `in_progress`) yang ditugaskan ke Petugas Lapangan yang sedang login, dengan filter berdasarkan status dan urgensi.

## 2. Traceability

- **FRs Covered:** OFC-002 (lihat tugas aktif), OFC-012 (Laporan Darurat via FAB).
- **Layer:** Presentation (`features/officer/screens/officer_home_screen.dart`).

## 3. UI/UX Requirements

- **AppBar:** Title "Tugas Saya" + filter chips horizontal: `Semua`, `Belum Dimulai`, `Sedang Dikerjakan`, `Mendesak`. **Actions (top-right):** bell icon (🔔) dengan unread badge → push ke [officer_notification.md](./officer_notification.md).
- **FAB:** Tombol darurat "+" untuk buat **Laporan Darurat** (officer bisa membuat laporan langsung dari lapangan, dengan GPS auto-fill). Opens AlertDialog dengan field judul + lokasi + koordinat otomatis dari `geolocator`.
- **Task Card:** tiap tugas menampilkan:
  - Judul laporan.
  - Alamat/lokasi.
  - Status badge (Belum Dimulai / Sedang Dikerjakan / Mendesak).
  - Urgency indicator (icon + warna).
  - Tanggal penugasan.
  - Tap → buka `OfficerTaskDetailScreen`.

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}`.
- **Read (stream):** `firestore.collection('reports').where('assignedOfficerId', isEqualTo: currentUid).where('status', whereIn: ['dispatched', 'in_progress']).orderBy('createdAt', descending: true).snapshots()`.
- **Filter chips:** client-side filter dari stream.
- **Create Emergency Report (OFC-012):** `collection('reports').add({ reporterId: officerUid, isAnonymous: false, status: "pending", ... })` dengan GPS dari `geolocator`.

## 5. Acceptance Criteria

### Scenario 1: Empty Task List

- **Given** officer has 0 dispatched/in_progress tasks.
- **When** they open the Tugas tab.
- **Then** empty state illustration + "Tidak ada tugas aktif saat ini."

### Scenario 2: Filter "Mendesak"

- **When** they tap the "Mendesak" filter.
- **Then** only tasks with `urgencyLevel: "high"` or `"critical"` are shown.

### Scenario 3: FAB Laporan Darurat

- **Given** officer di lapangan tanpa akses ke aplikasi citizen.
- **When** they tap FAB "+" di Tugas tab.
- **Then** AlertDialog muncul dengan field judul + lokasi + koordinat otomatis (GPS).
- **And** submit → new report dibuat dengan `status: "pending"`, muncul di admin report list.

## Implementation Reference

- File: `lib/features/officer/screens/officer_home_screen.dart`
- `OfficerHomeScreen` is the wrapper; `_OfficerHomeScreenState._buildActiveTasksView()` renders the list.

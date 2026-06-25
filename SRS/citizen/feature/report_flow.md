# Buat Laporan (Report Flow — Multi-Step Wizard)

## 1. Overview

Wizard multi-step untuk warga membuat laporan infrastruktur baru. Di-trigger dari FAB di tengah bottom navigation (di-dock ke BottomAppBar), atau dari hero CTA di Dashboard.

## 2. Traceability

- **FRs Covered:** CIT-001 (create report), CIT-002 (anonymous toggle), CIT-012 (planned: emergency report from FAB).
- **Notification FR:** NOTIF-001 (new report masuk → FCM ke Admin).
- **Layer:** Presentation + Data (`features/reports/presentation/screens/report_flow_screen.dart` + `FirebaseReportsRepository.createReport()`).

## 3. UI/UX Requirements

### 3.1 Flow Steps

1. **Step 1 — Kategori:** Pilih kategori (Jalan, Drainase, Penerangan, dll) dari list.
2. **Step 2 — Foto:** Ambil foto dari kamera atau pilih dari galeri. Preview + retake.
3. **Step 3 — Lokasi:** Auto-detect via GPS + reverse geocode. User bisa adjust pin di peta kecil atau ketik alamat manual.
4. **Step 4 — Detail:** Input judul + deskripsi + tingkat urgensi (Rendah/Biasa/Tinggi/Darurat).
5. **Step 5 — Anonimitas:** Toggle "Sembunyikan nama saya (Anonim)" + preview summary.
6. **Step 6 — Submit:** Loading → success screen dengan nomor tiket (format `LPR-YYYY-NNNNNNN`).

### 3.2 Per-Step UI

- **AppBar:** Title step-specific, back button (kecuali step 1).
- **Progress indicator:** linear di top, atau step counter "Step 2/6".
- **CTA button:** "Lanjut" (step 1-5) atau "Kirim Laporan" (step 6).
- **Permission handling:** lihat [app-overview.md §2.1](../app-overview.md#21-permissions--privacy) untuk izin lokasi & kamera.

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}`, Firebase Storage `/reports/{reportId}/photo.jpg`.
- **Report ID:** generated client-side as `LPR-YYYY-NNNNNNN` (deterministic — same ID untuk storage path dan Firestore doc).
- **Input (Submit):**
  1. `Storage.ref('reports/{reportId}/photo.jpg').putFile(photo, SettableMetadata(contentType: 'image/jpeg'))` → `photoUrl`.
  2. `collection('reports').doc(reportId).set(ReportModel.toFirestore(reportId, reporterId, isAnonymous, category, photoUrls, lat, lng, address, description, severity))`.
- **Rollback:** Jika Firestore write gagal setelah Storage upload sukses, hapus foto yatim (best-effort) untuk mencegah orphan files.
- **Expected Output:** Report dibuat dengan `status: "pending"`. Cloud Function `onCreate` di `/reports` → FCM ke Admin (NOTIF-001).

## 5. Acceptance Criteria

### Scenario 1: Successful Submit

- **Given** a citizen has filled all steps with valid data.
- **When** they tap "Kirim Laporan".
- **Then** the photo uploads to Storage.
- **And** the Firestore doc is created dengan `status: "pending"`.
- **And** they see the success screen with ticket number.
- **And** Admin menerima FCM notification (NOTIF-001).

### Scenario 2: Offline / Network Failure

- **When** the upload fails (no network / timeout).
- **Then** a SnackBar appears: "Gagal mengirim laporan. Coba lagi."
- **And** the user stays on the submit step with their data preserved.

### Scenario 3: Anonymous Toggle

- **Given** citizen on Step 5.
- **When** mereka toggle "Sembunyikan nama saya" ON.
- **Then** `isAnonymous: true` disimpan di Firestore.
- **And** admin UI menampilkan "Anonim" (BR-ADM-001).
- **But** `reporterId` tetap ada di DB untuk notifikasi.

## Implementation Reference

- File: `lib/features/reports/presentation/screens/report_flow_screen.dart`
- Route: `AppRoutes.createReport`
- Repository: `FirebaseReportsRepository.createReport()` (Data layer).

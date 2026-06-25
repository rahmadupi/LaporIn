# Officer Task Detail (Detail Tugas)

## 1. Overview

Halaman detail satu tugas yang ditugaskan ke Petugas Lapangan. Menampilkan info lengkap + action buttons sesuai status saat ini.

## 2. Traceability

- **FRs Covered:** OFC-005 (start), OFC-007 (complete), OFC-008 (reject).
- **Layer:** Presentation (`features/officer/screens/officer_task_detail_screen.dart`).

## 3. UI/UX Requirements

- **AppBar:** Back button + title "Detail Tugas".
- **Hero image:** foto laporan asli.
- **Info block:**
  - Judul + deskripsi.
  - Lokasi (alamat + koordinat).
  - Tingkat urgensi (color-coded badge).
  - Status saat ini.
  - Tanggal penugasan.
- **Action buttons (berubah sesuai status):**
  - Jika `dispatched`: tombol **"Mulai Pengerjaan"** (→ set status `in_progress`).
  - Jika `in_progress`: tombol **"Unggah Bukti"** (→ buka `OfficerProofScreen`) + **"Selesaikan"** (→ selesai tanpa bukti, optional).
  - Tombol **"Tolak Tugas"** (selalu tersedia) → kembali ke `in_review`, admin dinotifikasi.

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}`.
- **Read:** `widget.taskData` (passed dari list view) — `Map<String, dynamic>`.
- **Update Status (OFC-005):** `firestore.collection('reports').doc(taskId).update({ status: 'in_progress', startedAt: serverTimestamp() })`.
- **Reject Task (OFC-008):** `update({ status: 'in_review', rejectComment: reason })` + admin FCM trigger.
- **Complete Task (OFC-007):** setelah bukti di-upload via `OfficerProofScreen`, status berubah ke `resolved` + `completedAt: serverTimestamp()`.

## 5. Acceptance Criteria

### Scenario 1: Start Work (OFC-005)

- **Given** task status `dispatched`.
- **When** officer taps "Mulai Pengerjaan".
- **Then** status changes to `in_progress`, `startedAt` recorded.
- **And** UI refreshes to show the next set of action buttons.

### Scenario 2: Complete via Proof Upload (OFC-007)

- **Given** task `status: "in_progress"`.
- **When** officer uploads bukti via `OfficerProofScreen` → kembali ke Task Detail → tap "Selesaikan".
- **Then** status berubah ke `resolved`, `completedAt` recorded.
- **And** Admin menerima FCM (NOTIF-002 — lihat [admin/feature/dispatch_workflow.md](../admin/feature/dispatch_workflow.md)).

### Scenario 3: Reject Assignment (OFC-008)

- **When** officer taps "Tolak Tugas" + provides reason.
- **Then** task returns to `in_review` and admin receives FCM notification.

## Implementation Reference

- File: `lib/features/officer/screens/officer_task_detail_screen.dart`
- Constructor: `OfficerTaskDetailScreen({ required String taskId, required Map<String, dynamic> taskData })`.

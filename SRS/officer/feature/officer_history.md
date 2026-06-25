# Officer Report History (Riwayat)

## 1. Overview

Daftar tugas yang **sudah selesai / ditolak / dibatalkan** oleh Petugas Lapangan yang sedang login — arsip personal untuk referensi dan audit.

## 2. Traceability

- **FRs Covered:** OFC-009.
- **Layer:** Presentation (`features/officer/screens/officer_history_screen.dart`).

## 3. UI/UX Requirements

- **AppBar:** Title "Riwayat Tugas". **Actions (top-right):** bell icon (🔔) → [officer_notification.md](./officer_notification.md).
- **Filter chips:** `Selesai`, `Ditolak`, `Dibatalkan` (default: semua).
- **Search bar:** Pencarian by judul.
- **List:** tiap item menampilkan judul, tanggal selesai, status badge, rating dari admin (jika ada).
- **Tap item:** buka read-only view (atau `OfficerTaskDetailScreen` dalam mode read-only).

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports/{reportId}`.
- **Read (stream):** `firestore.collection('reports').where('assignedOfficerId', isEqualTo: currentUid).where('status', whereIn: ['resolved', 'rejected']).orderBy('updatedAt', descending: true).snapshots()`.

## 5. Acceptance Criteria

### Scenario 1: Status Filter

- **Given** officer has 8 resolved + 2 rejected tasks.
- **When** they tap "Ditolak".
- **Then** only the 2 rejected tasks are shown.

### Scenario 2: Reopen Read-only View

- **When** they tap an item.
- **Then** `OfficerTaskDetailScreen` opens in read-only mode (no action buttons enabled).

## Implementation Reference

- File: `lib/features/officer/screens/officer_history_screen.dart`.

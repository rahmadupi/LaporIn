# Officer Notification Page (Halaman Notifikasi)

> **Status:** 🟡 Planned (officer saat ini hanya punya SnackBar foreground listener di `main.dart`; belum ada dedicated screen).

## 1. Overview

Halaman untuk menampilkan daftar notifikasi yang diterima Petugas Lapangan — penugasan baru dari admin, validasi hasil kerja, broadcast sistem, dll.

> **Akses:** Halaman ini **BUKAN** tab di bottom navigation. Hanya bisa diakses via **bell icon (🔔)** di pojok kanan atas AppBar dari layar Home / History / Profile / Map. Tap bell → push ke `OfficerNotificationScreen`.

## 2. Traceability

- **FRs Covered:** OFC-004 (FCM dispatch notif), OFC-011 (logout dari notif page), OFC-013 (notif bell access).
- **Notification FR:** NOTIF-002 (Update status dari petugas → Admin).
- **Layer:** Presentation (planned `features/officer/screens/officer_notification_screen.dart`).

## 3. UI/UX Requirements

- **AppBar:**
  - Title "Notifikasi" (center, bold).
  - **Leading:** back button (←).
  - **Actions (top-right corner):**
    - **Bell icon (🔔)** — opsional dengan badge unread count.
    - **Logout icon (🚪)** — `Icons.logout`, konfirmasi lalu sign out + redirect ke `OfficerLoginScreen`.

- **Filter chips:** `Semua`, `Belum Dibaca`, `Tugas`, `Sistem`.

- **List:** tiap item menampilkan icon tipe, judul, body preview, timestamp, unread indicator.
  - Tap → mark as read + deep-link ke konten (Task Detail / Report Detail).

- **Empty state:** ilustrasi + "Belum ada notifikasi."

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/users/{uid}/notifications/{notificationId}`.
- **Read (stream):** `collection('notifications').where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots()`.
- **Mark as Read:** `update({ isRead: true })`.

## 5. Deep-link Behavior

| Notifikasi Tipe    | Tujuan                            |
| :----------------- | :-------------------------------- |
| `new_dispatch`     | `OfficerTaskDetailScreen(taskId)` |
| `report_validated` | `OfficerHistoryScreen`            |
| `report_rejected`  | `OfficerTaskDetailScreen(taskId)` |
| `system`           | Tetap di NotificationScreen       |

## 6. Acceptance Criteria

### Scenario 1: Akses via Bell

- **Given** officer on Home (Tugas) tab.
- **When** they tap the bell icon di pojok kanan atas AppBar.
- **Then** they are navigated (push) ke `OfficerNotificationScreen`.
- **And** bottom navigation tersembunyi.

### Scenario 2: Global Logout dari Notification Page

- **When** they tap logout icon di AppBar.
- **Then** `fcmToken = null` di Firestore → `FirebaseAuth.signOut()` → `Navigator.pushAndRemoveUntil(...OfficerLoginScreen())` setelah konfirmasi.

## Implementation Notes

- Officer app belum memiliki `OfficerNotificationScreen` terpisah — bisa reuse `NotificationScreen` dari citizen (shared component) atau buat dedicated dengan filter berbeda.
- `NotificationService` di officer saat ini hanya handle topic-based ("relawan"), belum ada per-user stream. Perlu ditambah agar unread count per-officer works.

## Implementation Reference (planned)

- File: `lib/features/officer/screens/officer_notification_screen.dart` (planned)
- Reuse: `NotificationTile` widget dari shared component atau citizen-app.

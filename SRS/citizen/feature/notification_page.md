# Notification Page (Halaman Notifikasi)

## 1. Overview

Halaman untuk menampilkan daftar notifikasi yang diterima warga — status laporan berubah, komentar baru dari admin, sistem announcement, dll.

> **Akses:** Halaman ini **BUKAN** tab di bottom navigation. Hanya bisa diakses via **bell icon (🔔)** di pojok kanan atas AppBar dari layar Home / History / Profile. Tap bell → push ke route `AppRoutes.citizenNotifications`.

## 2. Traceability

- **FRs Covered:** CIT-004 (notif saat status berubah), CIT-010 (logout dari notif page).
- **Layer:** Presentation (`features/notifications/presentation/screens/notification_screen.dart`).

## 3. UI/UX Requirements

- **AppBar:**
  - Title "Notifikasi" (center, bold).
  - **Leading:** back button (←).
  - **Actions (top-right corner):**
    - **Bell icon (🔔)** — indicator halaman ini sendiri, opsional dengan badge unread count.
    - **Logout icon (🚪)** — `Icons.logout`, memanggil `AuthProvider.signOut()` lalu redirect ke Login. Lokasi logout "global" selain tile logout di Profile.

- **Filter chips row:** `Semua`, `Belum Dibaca`, `Laporan`, `Sistem` — filter cepat per kategori.

- **List (`NotificationTile`):** tiap item menampilkan:
  - Icon berdasarkan tipe notifikasi (laporan / komentar / sistem).
  - Judul notifikasi.
  - Body preview (2 baris max).
  - Timestamp relative ("5 menit lalu").
  - Unread indicator (blue dot di kiri).
  - Tap → tandai dibaca + deep-link ke konten terkait.

- **Empty state:** ilustrasi + "Belum ada notifikasi."
- **Pull-to-refresh:** sync manual dengan Firestore.

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/users/{uid}/notifications/{notificationId}`.
- **Read (stream):** `collection('notifications').where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots()`.
- **Mark as Read:** `update({ isRead: true })` per dokumen.
- **Mark All as Read:** batch update semua unread (admin task — planned).
- **FCM Trigger:** di-handle oleh `NotificationService` (foreground banner + deep-link ke route).

## 5. Deep-link Behavior

| Notifikasi Tipe         | Tujuan saat di-tap                                  |
| :---------------------- | :-------------------------------------------------- |
| `report_status_changed` | `ReportDetailScreen(reportId)`                      |
| `comment_added`         | `ReportDetailScreen(reportId)` (scroll ke komentar) |
| `system`                | Tetap di NotificationScreen                         |
| `appeal_response`       | `ReportHistoryScreen`                               |

## 6. Acceptance Criteria

### Scenario 1: Akses via Bell

- **Given** citizen on Home tab.
- **When** they tap the bell icon di pojok kanan atas AppBar.
- **Then** they are navigated (push) ke NotificationScreen.
- **And** the bottom navigation is hidden (full-screen modal-ish experience).

### Scenario 2: Mark as Read

- **Given** 3 unread notifications.
- **When** they tap salah satu.
- **Then** notification ditandai `isRead: true` (blue dot hilang).
- **And** badge count di bell icon AppBar sumber berkurang 1.
- **And** they di-deep-link ke konten terkait.

### Scenario 3: Global Logout dari Notification Page

- **When** they tap logout icon di AppBar NotificationScreen.
- **Then** konfirmasi dialog muncul.
- **And** confirming → `fcmToken = null` di Firestore → `FirebaseAuth.signOut()` → navigasi ke Login + clear session.

## Implementation Reference

- File: `lib/features/notifications/presentation/screens/notification_screen.dart`
- Route: `AppRoutes.citizenNotifications` (registered di `main.dart` MaterialApp `routes:`).
- Widget: `NotificationTile` di `lib/features/notifications/presentation/widgets/notification_tile.dart`.
- Entity: `AppNotification` di `lib/features/notifications/domain/entities/`.

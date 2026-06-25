# Citizen Home / Dashboard (Beranda)

## 1. Overview

Landing tab setelah login sebagai warga. Menampilkan ringkasan singkat dan CTA utama untuk buat laporan.

## 2. Traceability

- **FRs Covered:** CIT-001, CIT-003, CIT-004 (notif bell).
- **Layer:** Presentation (`features/citizen/presentation/screens/citizen_home_screen.dart`).

## 3. UI/UX Requirements

- **AppBar:** Logo "LaporIn" (kiri) + **bell icon (🔔) di pojok kanan atas** dengan badge unread count. Tap bell → push ke [notification_page.md](./notification_page.md).
- **Greeting block:** "Selamat Pagi/Siang/Malam, [Nama]" + subtitle ringkas.
- **Hero CTA Card:** "Buat Laporan" dengan gradient background + icon kamera.
- **Stats Row** (placeholder/mock untuk release awal):
  - "Laporan Aktif" (count `in_progress` / `dispatched` milik user).
  - "Selesai Bulan Ini" (count `resolved` bulan ini).
- **Recent Reports List:** 3-5 laporan terakhir user (horizontal scroll atau list vertikal ringkas).

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/reports`, `/users/{uid}`.
- **Read (Recent Reports):** Firestore query `where("reporterId", "==", currentUid) orderBy createdAt desc limit 5` — stream.
- **Read (Unread Notif Count):** `/users/{uid}/notifications where isRead == false` count (atau field agregat `unreadNotifCount` di user doc).
- **Read (User Profile):** cached dari `AuthProvider.user` (no extra Firestore call).

## 5. Acceptance Criteria

### Scenario 1: Empty State

- **Given** a citizen with 0 reports.
- **When** they land on Dashboard.
- **Then** the Recent Reports section shows empty state illustration + "Belum ada laporan. Yuk buat yang pertama!"
- **And** tapping the FAB navigates to `ReportFlowScreen` (route `AppRoutes.createReport`).

### Scenario 2: Bell Badge

- **Given** 3 unread notifications.
- **When** Dashboard is rendered.
- **Then** the bell icon shows a badge with `3`.
- **And** tapping the bell navigates to `NotificationScreen` dengan badge cleared.

## Implementation Reference

- File: `lib/features/citizen/presentation/screens/citizen_home_screen.dart`
- Navigation: rendered as tab index 0 in `CitizenMainNavigation`.

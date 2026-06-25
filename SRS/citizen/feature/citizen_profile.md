# Citizen Profile (Profil Saya)

## 1. Overview

Halaman profil warga — menampilkan data diri, statistik kontribusi, daftar menu pengaturan, dan tombol logout.

## 2. Traceability

- **FRs Covered:** CIT-010 (Logout), CIT-011 (Toggle FCM).
- **Layer:** Presentation (`features/citizen/presentation/screens/citizen_profile_screen.dart`).

## 3. UI/UX Requirements

- **AppBar:** Title "Profil Saya" (center, bold). **Actions (top-right, urutan dari luar ke dalam):**
  - **Bell icon (🔔)** — akses cepat ke [notification_page.md](./notification_page.md), dengan badge unread.
  - **Settings icon (⚙️)** — planned (saat ini no-op).
- **ProfileHeaderWidget:** Avatar bulat (initial nama) + nama + email.
- **Stats Row:** 2 stat cards (Laporan Selesai, Poin Kontribusi).
- **Menu tiles:**
  - 🔔 **Pengaturan Notifikasi** → toggle FCM.
  - 🛡 **Privasi & Anonimitas** → info tentang anonymity.
  - 🌐 **Bahasa** → ID/EN switch.
  - ❓ **Bantuan & FAQ** → link eksternal/halaman statis.
  - ℹ️ **Tentang LaporIn** → versi + credits.
  - 🚪 **Keluar** (Logout) → memanggil `AuthProvider.signOut()`.

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/users/{uid}`.
- **Read User:** `context.read<AuthProvider>().user` (cached setelah login — tidak ada Firestore call tambahan).
- **Update Notification Preference (CIT-011):** `update({ fcmToken: <current or null> })` di `/users/{uid}`.
- **Logout (CIT-010):** `update({ fcmToken: null })` di `/users/{uid}` → `FirebaseAuth.signOut()` → clear local storage → `Navigator.pushReplacementNamed(AppRoutes.login)`.

## 5. Acceptance Criteria

### Scenario 1: Logout

- **Given** a logged-in citizen on the Profile tab.
- **When** they tap "Keluar" → confirm in dialog.
- **Then** `/users/{uid}.fcmToken` is set to `null`.
- **And** Firebase Auth session is cleared.
- **And** local storage is cleared.
- **And** they are redirected to the Landing Page.

### Scenario 2: Toggle Notification

- **Given** citizen on Profile tab.
- **When** they toggle "Pengaturan Notifikasi" OFF.
- **Then** `fcmToken` field di `/users/{uid}` di-set ke `null`.
- **And** mereka berhenti menerima push notification.

## Implementation Reference

- File: `lib/features/citizen/presentation/screens/citizen_profile_screen.dart`
- Widgets: `profile_header_widget.dart`, `profile_menu_tile.dart`, `stat_item_card.dart`.

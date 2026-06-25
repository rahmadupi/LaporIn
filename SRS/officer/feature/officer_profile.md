# Officer Profile (Profil Relawan)

## 1. Overview

Halaman profil Petugas Lapangan — menampilkan data dari `/users/{uid}`, statistik tugas, dan tombol logout.

## 2. Traceability

- **FRs Covered:** OFC-010 (manage profile), OFC-011 (logout), OFC-013 (notif bell).
- **Layer:** Presentation (`features/officer/screens/officer_profile_screen.dart`).

## 3. UI/UX Requirements

- **AppBar:** Title "Profil Relawan". **Actions (top-right):** bell icon (🔔) dengan unread badge → push ke [officer_notification.md](./officer_notification.md).
- **Avatar circle:** icon `Icons.person` (placeholder — planned: upload foto).
- **Nama & Role:** dari field `name` dan `role` di dokumen user.
- **Stat Card:** "Tugas Selesai" + "Rating Bintang" (2 kolom dengan divider).
- **Logout Tile:** "Keluar Aplikasi" (red icon + text), tap → konfirmasi dialog → kembali ke Login.

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/users/{uid}`.
- **Read User:** `firestore.collection('users').doc(currentUser.uid).get()` — **TODO**: replace hard-coded `User1` dengan `currentUser.uid`.
- **Logout (OFC-011):** `update({ fcmToken: null })` di `/users/{uid}` → `FirebaseAuth.signOut()` → clear local storage → `Navigator.pushAndRemoveUntil(...OfficerLoginScreen())`.

## 5. Acceptance Criteria

### Scenario 1: Display Profile

- **Given** officer logged in with `name: "Andi"`, `role: "officer"`, `completed_tasks: 12`, `rating: 4.7`.
- **When** they open Profile tab.
- **Then** UI shows "Andi", "officer", stat "12" / "4.7".

### Scenario 2: Logout Confirmation

- **When** they tap "Keluar Aplikasi".
- **Then** AlertDialog appears: "Apakah Anda yakin ingin keluar dari aplikasi?" with `Batal` / `Keluar` actions.
- **And** confirming `Keluar` → `/users/{uid}.fcmToken = null` → `FirebaseAuth.signOut()` → clear local storage → navigates to Login screen, removing all previous routes.

## Implementation Reference

- File: `lib/features/officer/screens/officer_profile_screen.dart`
- Reads from `/users/{uid}` collection (saat ini hard-coded `User1` — perlu refactor).

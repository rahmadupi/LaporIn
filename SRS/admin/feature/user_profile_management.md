# Profile & User Management (Profil & Moderasi Akun)

## 1. Overview

Admins can manage their own personal settings (Profile) as well as moderate the system by banning malicious Citizens or Officers who abuse the platform.

## 2. Traceability

- **FRs Covered:** ADM-018, ADM-019

## 3. UI/UX Requirements

- **Profile Page:** Form to update Display Name, change password, and toggle FCM notification preferences.
- **Logout Button:** Tombol "Log Out" yang mengarahkan ke Landing Page. Menghapus session dari local storage.
- **Delete Account Button:** Tombol "Hapus Akun" dengan konfirmasityped (isi "HAPUS"). Jika diklik:
  1. Firestore user document di-delete
  2. Firebase Auth user di-delete via Cloud Function
  3. Redirect ke Landing Page
- **User Moderation:** Accessed via clicking a Citizen's name on a report. Includes a critical action button: "Ban User". Requires a typed confirmation (e.g., "Type BAN to confirm").

## 4. Database Interactions (Data Layer)

- **Target Collections:** `/users/{uid}`
- **Input (Update Profile):** `{ "fullName": "New Name", "fcmToken": "new_token" }` + Firebase Auth profile update.
- **Input (Log Out):** `{ "fcmToken": null }` + `FirebaseAuth.instance.signOut()` + clear local storage.
- **Input (Delete Account):** Cloud Function: Delete Firebase Auth user + Delete Firestore document `/users/{uid}`.
- **Input (Ban User):** Update `/users/{targetUid}` -> `{ "isActive": false }`.
- **Expected Output:** Cloud Function listens to `isActive: false` trigger, interfaces with Firebase Admin SDK, and revokes the user's Auth refresh tokens, forcing them to log out globally.

## 5. Acceptance Criteria

### Scenario 1: Log Out

- **Given** Admin sedang login di app.
- **When** Admin klik tombol "Log Out".
- **Then** Firebase Auth session di-clear.
- **And** Local storage di-clear.
- **And** Admin di-redirect ke Landing Page.

### Scenario 2: Delete Account

- **Given** Admin klik "Hapus Akun" dan mengetik "HAPUS".
- **When** Admin klik konfirmasi.
- **Then** Firestore document `/users/{uid}` di-delete.
- **And** Cloud Function menghapus Firebase Auth user.
- **And** Admin di-redirect ke Landing Page.

### Scenario 3: Banning a Spammer

- **Given** an Admin identifies a Citizen submitting false reports.
- **When** the Admin executes the "Ban User" action.
- **Then** the Citizen's Firestore profile is marked `isActive: false`.
- **And** a Cloud Function revokes their Firebase Auth session.
- **And** the Citizen is immediately kicked to the Login screen if they are currently using the app.

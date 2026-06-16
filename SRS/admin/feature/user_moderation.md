# User Moderation & Banned Users (Daftar Pengguna Diblokir)

## 1. Overview

User Moderation page provides Admin dengan kemampuan untuk melihat daftar pengguna yang diblokir (banned) dan melakukan unbanned jika diperlukan. Akses ke halaman ini melalui Dashboard shortcut.

## 2. Traceability

- **FRs Covered:** ADM-019
- **Related:** user_profile_management.md

## 3. UI/UX Requirements

- **Banned Users List:** Tabel/kartu menampilkan user yang `isActive == false`.
  - Kolom: Nama, Email, Role (Citizen/Officer), Ban Reason, Banned At, Banned By Admin.
- **Unban Button:** Aksi untuk mengembalikan akses user (`isActive: true`).
- **Search/Filter:** Filter berdasarkan role atau rentang tanggal.
- **Accessed via:** Dashboard → "Banned Users" shortcut card.

## 4. Database Interactions (Data Layer)

- **Target Collection:** `/users`
- **Query (Banned List):** `where("isActive", "==", false)`
- **Input (Unban):** Update `/users/{uid}` -> `{ "isActive": true }`
- **Expected Output:** User dapat login kembali. Cloud Function merevoke ban status.

## 5. Acceptance Criteria

- **Scenario 1: Viewing Banned Users**
  - **Given** Admin membuka halaman Banned Users.
  - **When** halaman dimuat.
  - **Then** semua user dengan `isActive: false` ditampilkan.
- **Scenario 2: Unban User**
  - **Given** Admin mengklik "Unban" pada user tertentu.
  - **When** Admin mengkonfirmasi.
  - **Then** `isActive` diubah ke `true`.
  - **And** User dapat login kembali.

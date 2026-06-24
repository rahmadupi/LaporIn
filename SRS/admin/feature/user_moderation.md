# User Moderation & Banned Users (Daftar Pengguna Diblokir)

## 1. Overview

User Moderation page provides Admin dengan kemampuan untuk melihat daftar pengguna yang diblokir (banned) dan melakukan unbanned jika diperlukan. Akses ke halaman ini melalui Dashboard shortcut.

Additionally, this module includes the **Officer Approval Queue** — a dedicated section listing all officer accounts that are pending admin approval before they can log in.

Finally, this module also covers **Dormant Account Management** — admin dapat melihat daftar akun dormant (`status == "inActive"`) dan me-reactivate mereka secara manual jika user tidak bisa melakukan re-activation sendiri.

## 2. Traceability

- **FRs Covered:** ADM-019, ADM-026
- **Related:** user_profile_management.md, register_page.md, auth_session.md

## 3. UI/UX Requirements

### 3.1 Banned Users List

- **Banned Users List:** Tabel/kartu menampilkan user yang `status == "banned"`.
  - Kolom: Nama, Email, Role (Citizen/Officer), Ban Reason, Banned At, Banned By Admin.
- **Unban Button:** Aksi untuk mengembalikan akses user (`status: "active"`).
- **Search/Filter:** Filter berdasarkan role atau rentang tanggal.
- **Accessed via:** Dashboard → "Banned Users" shortcut card.

### 3.2 Officer Approval Queue

- **Pending Officers List:** Daftar officer dengan `status == "pending"`.
  - Kolom: Nama, Email, Nomor HP, District, Tanggal Pendaftaran.
  - Aksi: **"Setujui"** (approve) atau **"Tolak"** (reject/delete).
- **Approve Flow:**
  1. Admin klik "Setujui"
  2. Firestore update: `status: "active"`, `approvedBy: adminUid`, `approvedAt: Timestamp`
  3. Email dikirim ke officer: "Akun Anda telah disetujui. Silakan login."
- **Reject Flow:**
  1. Admin klik "Tolak"
  2. Konfirmasi dengan alasan (text input)
  3. Firestore: `status: "banned"` (dengan `banReason` berisi alasan penolakan) atau dokumen dihapus
  4. Firebase Auth user dinonaktifkan via Cloud Function
  5. Email dikirim ke officer: "Pendaftaran petugas ditolak. [Alasan]. Hubungi admin untuk informasi lebih lanjut."

### 3.3 Dormant Users List (Akun Dormant)

- **Dormant Users List:** Tabel/kartu menampilkan user yang `status == "inActive"`.
  - Kolom: Nama, Email, Role, Last Sign-In, Inactive Since.
- **Reactivate Button:** Aksi untuk mengembalikan akun dormant ke `status: "active"`.
  - Use case: user tidak bisa melakukan re-activation sendiri (mis. kehilangan akses ke email) dan menghubungi admin.
- **Search/Filter:** Filter berdasarkan role atau rentang tanggal inactive.
- **Catatan:** Akun dormant BUKAN banned — tidak ada `banReason`/`bannedAt`. User dapat melakukan self re-activation lewat tombol "Aktifkan Kembali" di halaman login.

## 4. Database Interactions (Data Layer)

- **Target Collection:** `/users`
- **Query (Banned List):** `where("status", "==", "banned")`
- **Query (Pending Officers):** `where("role", "==", "officer")` AND `where("status", "==", "pending")`
- **Query (Dormant List):** `where("status", "==", "inActive")`
- **Input (Unban):** Update `/users/{uid}` -> `{ "status": "active" }` (dan hapus `banReason`/`bannedAt`/`bannedBy`)
- **Input (Approve Officer):** Update `/users/{uid}` -> `{ "status": "active", "approvedBy": "adminId", "approvedAt": Timestamp }`
- **Input (Reject Officer):** Update `/users/{uid}` -> `{ "status": "banned", "banReason": reason, "bannedAt": serverTimestamp, "bannedBy": adminId }` OR delete document
- **Input (Admin Reactivate Dormant):** Update `/users/{uid}` -> `{ "status": "active" }`
- **Input (User Self Reactivate Dormant):** Update `/users/{uid}` -> `{ "status": "active" }` (dipanggil dari tombol "Aktifkan Kembali" di login screen, setelah user berhasil melewati Firebase Auth credential check)
- **Expected Output (Unban):** User dapat login kembali. Cloud Function merevoke ban status.
- **Expected Output (Approve):** Officer dapat login. Email notifikasi dikirim ke alamat email officer.
- **Expected Output (Reject):** Officer account deactivated. Email notifikasi penolakan dikirim via Cloud Function (Email Engine/APIService).
- **Expected Output (Reactivate Dormant):** User dapat login kembali dengan kredensial yang sama. Data dan history laporan user tetap tersimpan.

## 5. Acceptance Criteria

### Scenario 1: Viewing Banned Users

- **Given** Admin membuka halaman Banned Users.
- **When** halaman dimuat.
- **Then** semua user dengan `status: "banned"` ditampilkan.

### Scenario 2: Unban User

- **Given** Admin mengklik "Unban" pada user tertentu.
- **When** Admin mengkonfirmasi.
- **Then** `status` diubah ke `"active"`.
- **And** User dapat login kembali.

### Scenario 3: Approve Officer

- **Given** Admin membuka halaman Persetujuan Petugas.
- **When** Admin mengklik "Setujui" pada seorang officer.
- **Then** `status` diubah ke `"active"` dengan `approvedBy` dan `approvedAt`.
- **And** Email notifikasi dikirim ke officer.
- **And** Officer dapat login ke workspace mereka.

### Scenario 4: Reject Officer

- **Given** Admin mengklik "Tolak" pada seorang officer.
- **When** Admin mengisi alasan penolakan dan mengkonfirmasi.
- **Then** `status` diubah ke `"banned"` (dengan `banReason`) atau dokumen dihapus.
- **And** Firebase Auth dinonaktifkan via Cloud Function.
- **And** Email notifikasi penolakan (beserta alasan) dikirim ke officer.

### Scenario 5: User Self-Reactivation (Dormant)

- **Given** user dengan `status: "inActive"` mencoba login.
- **When** user memasukkan kredensial yang valid dan klik "Aktifkan Kembali" di dormant card.
- **Then** `status` diubah ke `"active"`.
- **And** user otomatis sign-in dan masuk ke workspace sesuai role.

### Scenario 6: Admin Reactivate Dormant

- **Given** Admin membuka halaman Dormant Users.
- **When** Admin mengklik "Reactivate" pada seorang user.
- **Then** `status` diubah ke `"active"`.
- **And** user dapat login kembali dengan kredensial yang sama.

## 5. Acceptance Criteria

- **Scenario 1: Viewing Banned Users**
  - **Given** Admin membuka halaman Banned Users.
  - **When** halaman dimuat.
  - **Then** semua user dengan `status: "banned"` ditampilkan.
- **Scenario 2: Unban User**
  - **Given** Admin mengklik "Unban" pada user tertentu.
  - **When** Admin mengkonfirmasi.
  - **Then** `status` diubah ke `"active"`.
  - **And** User dapat login kembali.
- **Scenario 3: Approve Officer**
  - **Given** Admin membuka halaman Persetujuan Petugas.
  - **When** Admin mengklik "Setujui" pada seorang officer.
  - **Then** `status` diubah ke `"active"` dengan `approvedBy` dan `approvedAt`.
  - **And** Email notifikasi dikirim ke officer.
  - **And** Officer dapat login ke workspace mereka.
- **Scenario 4: Reject Officer**
  - **Given** Admin mengklik "Tolak" pada seorang officer.
  - **When** Admin mengisi alasan penolakan dan mengkonfirmasi.
  - **Then** `status` diubah ke `"banned"` (dengan `banReason`) atau dokumen dihapus.
  - **And** Firebase Auth dinonaktifkan via Cloud Function.
  - **And** Email notifikasi penolakan (beserta alasan) dikirim ke officer.

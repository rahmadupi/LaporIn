# Officer (Petugas Lapangan) Overview

> **Dokumen ini mengikuti standar SRS global — lihat:** [app-overview.md](../app-overview.md) untuk arsitektur keseluruhan, [system-architecture.md](../system-architecture.md) untuk layer DDD, dan [admin/admin-overview.md](../admin/admin-overview.md) untuk style template ini.
>
> Arsitektur: **App-Within-An-App** — Presentation layer Petugas Lapangan terisolasi di `lib/features/officer/`. Domain/Data layer bersama dengan admin & citizen di `lib/shared_domain_data/`.

## 1. Overview (Pendahuluan)

**Petugas Lapangan** (Field Officer) bertanggung jawab untuk melaksanakan perbaikan infrastruktur yang di-dispatch oleh Admin. Mereka dapat mengajukan diri untuk menangani laporan tertentu, memperbarui status laporan, mengunggah bukti penyelesaian, dan mengelola profil sendiri.

> **Penting:** Akun officer memerlukan **persetujuan admin** sebelum bisa login. Lihat [utility/register_page.md](../utility/register_page.md) untuk flow registrasi dan [admin/feature/user_moderation.md](../admin/feature/user_moderation.md) untuk proses approval.

## 1.1 Navigation Structure

Bottom navigation with **4 tabs** (no FAB — berbeda dari citizen):

```
┌─────────────────────────────────────────────────────┐
│  AppBar (varies per screen)                          │
├─────────────────────────────────────────────────────┤
│              [ Screen Body ]                         │
├─────────────────────────────────────────────────────┤
│  📋 Tugas │ � Peta │ �🗂 Laporan │ 📜 Riwayat │ 👤 Profil        │
└─────────────────────────────────────────────────────┘
```

| Index | Tab     | Screen                       | Purpose                                                                                |
| ----- | ------- | ---------------------------- | -------------------------------------------------------------------------------------- |
| 0     | Tugas   | `OfficerHomeScreen`          | Daftar tugas aktif (dispatched + in_progress) + filter + FAB darurat                  |
| 1     | Peta    | `OfficerPetaScreen`          | 🟡 Placeholder — peta interaktif dengan marker tugas                                   |
| 2     | Laporan | `OfficerLaporanScreen`       | 🟡 Placeholder — feed publik semua laporan (untuk self-request)                       |
| 3     | Riwayat | `OfficerHistoryScreen`       | ✅ Implemented — arsip tugas selesai/ditolak                                          |
| 4     | Profil  | `OfficerProfileScreen`       | ✅ Implemented — profil sederhana (nama + toggle notif + ganti password + hapus akun) |

> **Notification page is NOT in the bottom nav.** It is accessed exclusively via the **bell icon (🔔)** in the AppBar (top-right corner) — present on Home, History, and Profile screens. See [officer_notification.md](./feature/officer_notification.md).
>
> **FAB "Laporan Darurat"** muncul di tab Tugas (bukan di tengah bottom nav), untuk kasus officer di lapangan yang perlu membuat laporan langsung.

## 1.2 Page Inventory

| Spec File                                                    | Screen                | Status         |
| ------------------------------------------------------------ | --------------------- | -------------- |
| [officer_home.md](./feature/officer_home.md)                 | Tugas Aktif           | ✅ Implemented |
| [officer_laporan.md](./feature/officer_laporan.md)           | Laporan (Publik)      | 🟡 Planned     |
| [officer_history.md](./feature/officer_history.md)           | Riwayat               | ✅ Implemented |
| [officer_profile.md](./feature/officer_profile.md)           | Profil                | ✅ Implemented |
| [officer_task_detail.md](./feature/officer_task_detail.md)   | Detail Tugas          | ✅ Implemented |
| [officer_proof.md](./feature/officer_proof.md)               | Unggah Bukti          | ✅ Implemented |
| [officer_notification.md](./feature/officer_notification.md) | Notifikasi (via bell) | 🟡 Planned     |

## 2. Functional Requirements (FR) — Officer Layer (Petugas Lapangan)

Sesuai template [admin/admin-overview.md](../admin/admin-overview.md) § 2.1. FR lintas-role yang involve officer dicatat ulang di sini untuk traceability.

| ID          | Deskripsi Kebutuhan                                                                                                            | Target Implementasi (Serverless)                                                               |
| :---------- | :----------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------- |
| **OFC-001** | Petugas Lapangan dapat login dengan email/password setelah disetujui admin.                                                    | Firebase Auth + Firestore check `status == "active"` (jika `pending` / `banned` → ditolak)     |
| **OFC-002** | Petugas Lapangan dapat melihat daftar tugas aktif yang ditugaskan ke dirinya (`dispatched` / `in_progress`).                   | Firestore query `where("assignedOfficerId", "==", uid).where("status", whereIn: [...])         |
| **OFC-003** | Petugas Lapangan dapat mengajukan diri (self-request) untuk menangani laporan tertentu.                                        | Create `/reports/{reportId}/officer/{officerId}` dengan `status: "requested"`                  |
| **OFC-004** | Petugas Lapangan menerima notifikasi FCM saat ada dispatch baru dari Admin.                                                    | Cloud Function trigger di `/dispatches` → FCM topic `officer_{uid}` atau direct FCM            |
| **OFC-005** | Petugas Lapangan dapat mengubah status laporan dari `dispatched` → `in_progress` (Mulai Pengerjaan).                           | Firestore update + `startedAt: serverTimestamp()`                                              |
| **OFC-006** | Petugas Lapangan dapat mengunggah bukti pengerjaan (foto + deskripsi + GPS) melalui Officer Proof screen.                      | Upload ke ImgBB API → simpan URL di `/reports/{reportId}.proofUrl` + deskripsi                 |
| **OFC-007** | Petugas Lapangan dapat menyelesaikan tugas (`in_progress` → `resolved`).                                                       | Firestore update + `completedAt: serverTimestamp()` + Cloud Function `onUpdate` → FCM ke Admin |
| **OFC-008** | Petugas Lapangan dapat menolak tugas (kembali ke `in_review`, admin dinotifikasi).                                             | Firestore update + admin FCM trigger                                                           |
| **OFC-009** | Petugas Lapangan dapat melihat riwayat tugas (resolved / rejected) dengan filter dan search.                                   | Firestore query `where("status", whereIn: ["resolved", "rejected"])`                           |
| **OFC-010** | Petugas Lapangan dapat mengelola profil (displayName, phoneNumber, profilePhoto, `isAvailable`).                               | Firestore update di `/users/{uid}`                                                             |
| **OFC-011** | Petugas Lapangan dapat Log Out.                                                                                                | `FirebaseAuth.signOut()` + clear local storage + `fcmToken = null`                             |
| **OFC-012** | Petugas Lapangan dapat membuat Laporan Darurat dari lapangan (FAB di Home tab) dengan GPS auto-fill.                           | Reuse `ReportFlowScreen` ringkas + `geolocator`                                                |
| **OFC-013** | Petugas Lapangan dapat mengakses halaman notifikasi via bell icon di AppBar.                                                   | Push ke `OfficerNotificationScreen`                                                            |
| **OFC-014** | Petugas Lapangan dapat bekerja offline — bukti pengerjaan di-queue di Hive box `offline_proofs` lalu disinkronkan saat online. | `connectivity_plus` stream listener + Hive `box.put()` + auto-upload saat online               |

> **Cross-reference:** Status enum & lifecycle → [app-overview.md §3](../app-overview.md#3-alur-hidup-laporan-end-to-end-report-lifecycle). Dispatch flow → [admin/feature/dispatch_workflow.md](../admin/feature/dispatch_workflow.md). Data entities → [data-model.md](../data-model.md). DDD layers → [system-architecture.md §4](../system-architecture.md#4-class-architecture-domain-driven-design).

## 3. Security Rules

| Action                           | Officer | Admin | Citizen |
| -------------------------------- | ------- | ----- | ------- |
| View all reports                 | ❌      | ✅    | ❌      |
| View assigned reports only       | ✅      | ✅    | ❌      |
| Request to handle a report       | ✅      | ❌    | ❌      |
| Update status of assigned report | ✅      | ❌    | ❌      |
| Upload completion evidence       | ✅      | ❌    | ❌      |
| View officer directory           | ❌      | ✅    | ❌      |
| Dispatch officer                 | ❌      | ✅    | ❌      |
| Edit own profile                 | ✅      | ✅    | ✅      |

## 4. Acceptance Criteria

### Scenario 1: Officer Login Before Approval

- **Given** an officer registered but has not been approved by admin.
- **When** they attempt to log in.
- **Then** Firebase Auth succeeds but `status: "pending"` is detected.
- **And** the officer sees: _"Akun Anda belum disetujui Admin."_
- **And** they cannot access the officer workspace.

### Scenario 2: Dispatch Lifecycle (Officer Side)

- **Given** Admin has dispatched a report to officer (status `dispatched`).
- **When** officer taps "Mulai Pengerjaan" di Task Detail.
- **Then** status berubah ke `in_progress`, `startedAt` recorded.
- **When** officer lalu mengunggah bukti + tap "Selesaikan".
- **Then** status berubah ke `resolved`, Admin menerima FCM (NOTIF-002).

### Scenario 3: Offline Proof Upload

- **Given** officer di area tanpa sinyal.
- **When** mereka submit bukti pengerjaan.
- **Then** payload (foto base64 + metadata) disimpan di Hive `offline_proofs`.
- **When** koneksi pulih.
- **Then** antrian auto-upload ke ImgBB + Firestore.

### Scenario 2: Officer Self-Request

- **Given** an officer is browsing the report list and finds an unassigned report.
- **When** they tap "Saya Ingin Menangani Laporan Ini".
- **Then** a request document is created at `/reports/{reportId}/officer/{officerId}`.
- **And** the button changes to "Menunggu Persetujuan Admin".
- **When** Admin approves the request.
- **Then** the officer receives an FCM notification.
- **And** the report appears in the officer's Active Jobs list.

### Scenario 3: Officer Updates Report Status

- **Given** an officer has an active dispatch (status: `dispatched`).
- **When** they tap "Mulai Pengerjaan" and confirm.
- **Then** the report status changes to `in_progress`.
- **And** the admin receives an FCM notification.
- **And** the timeline in report detail shows "Pengerjaan dimulai: [timestamp]".

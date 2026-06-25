# Citizen (Warga) Overview

> **Dokumen ini mengikuti standar SRS global — lihat:** [app-overview.md](../app-overview.md) untuk arsitektur keseluruhan, [system-architecture.md](../system-architecture.md) untuk layer DDD, dan [admin/admin-overview.md](../admin/admin-overview.md) untuk style template ini.
>
> Arsitektur: **App-Within-An-App** — Presentation layer citizen terisolasi di `lib/features/citizen/`. Domain/Data layer bersama dengan admin & officer di `lib/shared_domain_data/`.

## 1. Overview (Pendahuluan)

**Warga** adalah pengguna umum yang membuat laporan kerusakan infrastruktur publik melalui aplikasi mobile. Mereka dapat memilih mode anonim atau publik, memantau progres laporan miliknya, dan berinteraksi via komentar serta appeal.

## 2. Navigation Structure

```
┌─────────────────────────────────────────────────────┐
│  AppBar (varies per screen)                          │
├─────────────────────────────────────────────────────┤
│                                                      │
│              [ Screen Body ]                         │
│                                                      │
├─────────────────────────────────────────────────────┤
│  Dashboard │ Laporan │   Buat  │  Riwayat │ Profil │
└─────────────────────────────────────────────────────┘
                    ▲
        FAB (FloatingActionButton) di tengah, di-dock
        ke BottomAppBar lewat CircularNotchedRectangle.
```

| Index | Tab       | Screen                 | Purpose                                                                          |
| ----- | --------- | ---------------------- | -------------------------------------------------------------------------------- |
| 0     | Dashboard | `CitizenHomeScreen`    | Ringkasan + CTA buat laporan                                                     |
| 1     | Peta      | `CitizenPetaScreen`    | 🟡 Placeholder — peta interaktif dengan marker laporan                          |
| 2     | Laporan   | `CitizenLaporanScreen` | 🟡 Placeholder — feed publik semua laporan di area                               |
| 3     | Riwayat   | `ReportHistoryScreen`  | ✅ Implemented — daftar **seluruh laporan** yang pernah dibuat warga              |
| 4     | Profil    | `CitizenProfileScreen` | ✅ Implemented — profil sederhana (nama + toggle notif + ganti password + hapus akun) |

> **Notification page is NOT in the bottom nav.** It is accessed exclusively via the **bell icon (🔔)** in the AppBar (top-right corner) — present on Home, History, and Profile screens. See [notification_page.md](./feature/notification_page.md).
>
> IndexedStack dipakai untuk mempertahankan state tiap tab (scroll position, dll) saat berpindah.

## 3. Functional Requirements (FR) — Citizen Layer

| ID          | Deskripsi                                                                                                                          | Target Implementasi                                                               |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **CIT-001** | Citizen dapat membuat laporan baru dengan foto, lokasi, kategori, deskripsi, dan tingkat urgensi.                                  | Firestore write ke `/reports` + Firebase Storage upload foto                      |
| **CIT-002** | Citizen dapat memilih apakah laporan dipublikasikan atas namanya atau anonim (BR-ADM-001: identity di-mask di UI, retained di DB). | Flag `isAnonymous` di dokumen laporan                                             |
| **CIT-003** | Citizen dapat melihat **seluruh laporan** yang pernah dibuatnya (semua status) dengan filter status dan pencarian judul.           | Firestore query `where("reporterId", "==", uid)` (no status filter — client-side) |
| **CIT-004** | Citizen mendapat notifikasi FCM saat status laporannya berubah (in_review, dispatched, in_progress, resolved, rejected).           | Cloud Function `onUpdate` di `/reports/{id}` → FCM target `reporterId`            |
| **CIT-005** | Citizen dapat mengajukan banding (appeal) untuk laporan yang ditolak admin.                                                        | Update field `appealRequested: true` + `appealReason`, `appealAt`                 |
| **CIT-006** | Citizen dapat memberi komentar pada laporan miliknya sendiri (atau laporan publik yang diizinkan).                                 | Write ke sub-collection `/reports/{id}/comments`                                  |
| **CIT-007** | Citizen dapat menghapus laporan miliknya sendiri hanya saat status masih `pending` (soft delete).                                  | Set `isDeleted: true` di Firestore                                                |
| **CIT-008** | Citizen dapat mengubah deskripsi laporan hanya saat status `pending`.                                                              | Firestore update dengan validasi status                                           |
| **CIT-009** | Citizen dapat memberikan rating (bintang + komentar) pada laporan yang sudah `resolved`.                                           | Write ke koleksi `/ratings`                                                       |
| **CIT-010** | Citizen dapat logout, menghapus FCM token dan local session.                                                                       | FirebaseAuth.signOut() + clear local storage                                      |

> **Catatan:** FR di atas mengikuti template dan nomor `CIT-NNN` dari [admin/admin-overview.md](../admin/admin-overview.md) (prefix `ADM-`). Status enum lihat [app-overview.md §3](../app-overview.md).

## 4. Privacy & Security Rules (Business Rules)

- **BR-CIT-001 (Anonymity):** Laporan dengan `isAnonymous: true` menampilkan "Anonim" di semua layer presentasi (admin, officer, publik). `reporterId` tetap disimpan di Firestore untuk kebutuhan notifikasi.
- **BR-CIT-002 (Ownership):** Citizen hanya boleh edit/delete laporan miliknya sendiri (validated by Firestore Security Rules + `auth.uid == reporterId`).
- **BR-CIT-003 (Edit Window):** Edit hanya diizinkan saat `status == "pending"`. Setelah admin accept (in_review), dokumen menjadi read-only untuk citizen.

## 5. Security Rules (Firestore)

| Action                                | Citizen | Admin | Officer                 |
| ------------------------------------- | ------- | ----- | ----------------------- |
| Membuat laporan                       | ✅      | ❌    | ❌                      |
| Read laporan sendiri                  | ✅      | ✅    | ❌                      |
| Read laporan publik/anonim            | ❌      | ✅    | partial (assigned only) |
| Edit/delete laporan sendiri (pending) | ✅      | ❌    | ❌                      |
| Komentar di laporan sendiri           | ✅      | ✅    | ❌                      |
| Komentar di laporan publik            | ❌      | ✅    | ❌                      |
| Submit rating (resolved)              | ✅      | ❌    | ❌                      |
| Submit appeal                         | ✅      | ❌    | ❌                      |

## 6. Page Inventory (linked feature specs)

| Spec File                                          | Screen              | Status         |
| -------------------------------------------------- | ------------------- | -------------- |
| [citizen_home.md](./feature/citizen_home.md)       | Dashboard / Beranda | ✅ Implemented |
| [citizen_laporan.md](./feature/citizen_laporan.md) | Laporan (Publik)    | 🟡 Planned     |

| [citizen_profile.md](./feature/citizen_profile.md) | Profil Saya | ✅ Implemented |
| [report_flow.md](./feature/report_flow.md) | Buat Laporan (FAB) | ✅ Implemented |
| [citizen_history.md](./feature/citizen_history.md) | Riwayat Laporan | ✅ Implemented || [citizen_laporan.md](./feature/citizen_laporan.md) | Laporan (Publik) | 🟡 Planned || [notification_page.md](./feature/notification_page.md) | Notifikasi (via bell) | ✅ Implemented |

### Scenario 1: Anonymous Report Creation

- **Given** a logged-in citizen on the Dashboard.
- **When** they tap the FAB "Buat Laporan" → complete the wizard → toggle "Anonim" → submit.
- **Then** a new document appears in `/reports` with `isAnonymous: true`.
- **And** the citizen's `displayName` is NOT rendered in admin's Report List (BR-ADM-001).
- **But** the FCM notification when status changes is still delivered to `reporterId`.

### Scenario 2: Edit Window Closed

- **Given** a citizen's report currently `status: "in_review"`.
- **When** they try to edit the description.
- **Then** the UI shows a SnackBar: _"Laporan tidak dapat diedit setelah diproses admin."_
- **And** no Firestore write occurs (rejected by Security Rules as backup).

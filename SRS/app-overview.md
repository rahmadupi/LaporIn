# Software Requirement Specification (SRS) - LaporIn Overview

## 1. Pendahuluan & Deskripsi Proyek

LaporIn adalah aplikasi pelaporan infrastruktur publik berbasis mobile yang dirancang untuk mempercepat penanganan fasilitas kota yang rusak. Platform ini memfasilitasi komunikasi dua arah yang transparan antara masyarakat (Citizen) dan pemerintah kota (Admin/City Official).

## 2. Arsitektur Komputasi (100% Serverless)

Aplikasi ini dibangun menggunakan arsitektur serverless penuh untuk menjamin kecepatan _deployment_, efisiensi biaya, dan skalabilitas otomatis tanpa pengelolaan server mandiri:

- **Frontend:** Flutter SDK (Multiplatform iOS/Android) + **Riverpod** (State Management)
- **Authentication:** Firebase Authentication (Custom Accounts + Google Sign-In)
- **Database:** Cloud Firestore (NoSQL Document-based)
- **Storage:** Firebase Cloud Storage (Media & Dokumen Foto)
- **Serverless Logic & Notification:** Firebase Cloud Functions & Cloud Messaging (FCM)
- **Location Service:** Geohashing Algorithm via Client Extension + Geolocator package
- **Domain Driven Design (DDD):** Dipakai untuk memisahkan logika bisnis inti dari detail implementasi teknis, memastikan modularitas dan maintainabilitas kode yang tinggi.

## 2.1 Permissions & Privacy

### Location Permission

Aplikasi LaporIn **meminta izin akses lokasi** (location permission) dari pengguna pada momen-momen berikut:

- **Saat pertama kali membuka aplikasi** (setelah onboarding): Dipakai untuk menentukan district/wilayah pengguna secara otomatis dan menyesuaikan konten map dan watch zones.
- **Saat membuat laporan baru (Citizen)**: Lokasi GPS diperlukan untuk menentukan koordinat otomatis titik kerusakan yang dilaporkan. Pengguna juga dapat menyesuaikan pin secara manual.
- **Saat membuka halaman Peta/Map**: Lokasi dipakai untuk centering peta pada posisi user.

**Catatan:**

- Izin lokasi bersifat **opsional** — pengguna dapat menolak, tetapi fitur yang bergantung pada lokasi (auto-fill koordinat laporan, centering map) akan memerlukan input manual.
- Data lokasi **tidak** disimpan ke Firestore kecuali saat membuat laporan atau mengatur watch zone.
- Aplikasi menampilkan **permission rationale** sebelum meminta izin (ditampilkan native OS).

| Permission             | Platform      | When Requested                 | consequence if Denied                                        |
| ---------------------- | ------------- | ------------------------------ | ------------------------------------------------------------ |
| Location (Approximate) | Android / iOS | First launch / Report creation | District auto-detect disabled; manual coordinate entry       |
| Location (Precise/GPS) | Android / iOS | Report creation                | Pin auto-placement disabled; manual map tap required         |
| Camera                 | Android / iOS | Report creation                | Photo capture disabled; must pick from gallery               |
| Notification           | Android / iOS | After login                    | Push notifications disabled; in-app notification center only |

## 3. Alur Hidup Laporan (End-to-End Report Lifecycle)

Siklus hidup sebuah laporan di dalam sistem LaporIn mengikuti alur berikut:

1. [Warga: Ambil Foto & Koordinat] ──> Status: PENDING
2. [Admin: Review]: Status: REJECTED (Selesai) / Status: IN REVIEW
3. [Admin: Dispatch Petugas]: Status: DISPATCHED
4. [Petugas: Perbaikan di Lokasi]: Status: IN PROGRESS
5. [Petugas: Laporan Hasil Perbaikan]: Status: IN PROGRESS (Menunggu Validasi Admin)
6. [Admin: Validasi Bukti, Warga: Validasi]: Status: RESOLVED (Selesai) / Status: REJECTED (Perbaikan Ulang)
7. [Petugas: Perbaikan ulang berdasarkan feedback]
8. [Admin: Validasi ulang]: Status: RESOLVED (Selesai) / Status: REJECTED (Perbaikan Ulang)
9. [Siklus berulang hingga laporan valid dan selesai]

### 3.1 Timeout & Auto-Return to PENDING

Jika petugas lapangan tidak memberikan update status dalam jangka waktu yang ditentukan (timeout), sistem akan mengembalikan laporan ke status PENDING secara otomatis:

- **Dispatch Timeout:** 24 jam sejak status DISPATCHED
- **In Progress Timeout:** 48 jam sejak status IN PROGRESS
- **Cloud Function:** Scheduled trigger harian memeriksa laporan yang timeout
- **Hasil:** Laporan kembali ke status PENDING, notifikasi dikirim ke Admin

### 3.2 Appeal Process (Banding)

Warga dapat mengajukan banding terhadap penolakan laporan:

- **Warga:** Dapat mengajukan appeal dalam 24 jam setelah status REJECTED
- **Alasan:** Warga wajib mengisi alasan banding
- **Lokasi:** Menu "Appeals" di level sama dengan Report List di halaman Reports
- **Admin:** Dapat menerima appeal (kembali ke IN REVIEW) atau menolak banding permanently

## 4. Role

- **Warga (Citizen):** Pengguna umum yang melaporkan kerusakan infrastruktur dengan mengunggah foto dan koordinat lokasi. Dapat memilih untuk melaporkan secara anonim atau publik.
- **Admin (City Official):** Petugas pemerintah kota yang bertanggung jawab untuk meninjau laporan, melakukan penugasan petugas lapangan, dan memoderasi komentar warga.
- **Petugas Lapangan (Field Officer):** Petugas yang menerima penugasan dari admin untuk melakukan perbaikan di lokasi yang dilaporkan. Mereka dapat memperbarui status laporan dan mengunggah bukti penyelesaian.

## 5. Glosarium Status Laporan

- **PENDING:** Laporan berhasil disimpan di database dan menunggu konfirmasi awal dari Admin.
- **IN REVIEW:** Laporan sedang diperiksa keabsahannya oleh jajaran Admin.
- **DISPATCHED:** Laporan telah divalidasi dan petugas lapangan telah dikirim ke titik lokasi koordinat.
- **IN PROGRESS:** Petugas lapangan sedang melakukan perbaikan di lokasi yang dilaporkan.
- **RESOLVED:** Pekerjaan perbaikan selesai dilakukan dan bukti foto penyelesaian telah diunggah oleh pihak otoritas.
- **REJECTED:** Laporan dinyatakan tidak valid, duplikat, atau mengandung informasi palsu.

## 6. Batasan Sistem (Out of Scope)

- Tidak mencakup sistem manajemen inventaris material perbaikan instansi terkait.
- Tidak mencakup kalkulasi anggaran biaya perbaikan atau integrasi sistem keuangan daerah.
- Fitur peta tidak menyediakan navigasi suara mengemudi (_turn-by-turn navigation_).
- Tidak menyediakan fitur navigasi layaknya google maps, hanya menampilkan koordinat dan lokasi titik laporan.

## 7. Asumsi & Ketergantungan

- Asumsi bahwa pengguna memiliki akses ke perangkat mobile dengan koneksi internet yang stabil.
- Ketergantungan pada layanan Firebase untuk autentikasi, database, penyimpanan, dan fungsi serverless.

## 8. Engineering & Deployment

Dokumen SRS engineering (version control, CI/CD, build, release, deployment):

- [Git Workflows — Build, Release, and Deployment](./engineering/git_workflows.md)
  — branching strategy (GitFlow), versioning (semver), CI pipeline (GitHub Actions),
  CD pipeline (tag-based deployment ke Play Store, App Store, Firebase Hosting),
  hotfix workflow, secrets management, branch protection rules, dan acceptance
  criteria workflow.

## 8. Kesimpulan

LaporIn bertujuan untuk meningkatkan efisiensi penanganan laporan infrastruktur publik dengan memanfaatkan teknologi serverless dan arsitektur modern. Dengan alur hidup laporan yang jelas dan sistem status yang transparan, LaporIn diharapkan dapat mempercepat proses perbaikan dan meningkatkan kepuasan masyarakat terhadap layanan publik.

## 9. Flow

Landing Page (Authentication Login/Register) ──> Role-Based App routing(Admin, Citizen, Officer)

## 10. Edge Cases

# Software Requirement Specification (SRS) - LaporIn Overview

## 1. Pendahuluan & Deskripsi Proyek

LaporIn adalah aplikasi pelaporan infrastruktur publik berbasis mobile yang dirancang untuk mempercepat penanganan fasilitas kota yang rusak. Platform ini memfasilitasi komunikasi dua arah yang transparan antara masyarakat (Citizen) dan pemerintah kota (Admin/City Official).

## 2. Arsitektur Komputasi (100% Serverless)

Aplikasi ini dibangun menggunakan arsitektur serverless penuh untuk menjamin kecepatan _deployment_, efisiensi biaya, dan skalabilitas otomatis tanpa pengelolaan server mandiri:

- **Frontend:** Flutter SDK (Multiplatform iOS/Android)
- **Authentication:** Firebase Authentication (Custom Accounts + Google Sign-In)
- **Database:** Cloud Firestore (NoSQL Document-based)
- **Storage:** Firebase Cloud Storage (Media & Dokumen Foto)
- **Serverless Logic & Notification:** Firebase Cloud Functions & Cloud Messaging (FCM)
- **Location Service:** Geohashing Algorithm via Client Extension
  ImplementasiDomain Driven Design (DDD) digunakan untuk memisahkan logika bisnis inti dari detail implementasi teknis, memastikan modularitas dan maintainabilitas kode yang tinggi.

## 3. Alur Hidup Laporan (End-to-End Report Lifecycle)

Siklus hidup sebuah laporan di dalam sistem LaporIn mengikuti alur berikut:

1. [Warga: Ambil Foto & Koordinat] ──> Status: PENDING
2. [Admin: Review]: Status: REJECTED (Selesai) / Status: IN REVIEW
3. [Admin: Dispatch Petugas]: Status: Dispatched
4. [Petugas: Perbaikan di Lokasi]: Status: IN PROGRESS
5. [Petugas: Laporan Hasil Perbaikan]: Status: IN PROGRESS (Menunggu Validasi Admin)
6. [Admin: Validasi Bukti, Warga: Validasi]: Status: RESOLVED (Selesai) / Status: REJECTED (Perbaikan Ulang)
7. [Petugas: Perbaikan ulang berdasarkan feedback]
8. [Admin: Validasi ulang]: Status: RESOLVED (Selesai) / Status: REJECTED (Perbaikan Ulang)
9. [Siklus berulang hingga laporan valid dan selesai]

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

## 8. Kesimpulan

LaporIn bertujuan untuk meningkatkan efisiensi penanganan laporan infrastruktur publik dengan memanfaatkan teknologi serverless dan arsitektur modern. Dengan alur hidup laporan yang jelas dan sistem status yang transparan, LaporIn diharapkan dapat mempercepat proses perbaikan dan meningkatkan kepuasan masyarakat terhadap layanan publik.

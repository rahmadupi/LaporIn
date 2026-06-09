## 2.1 Kebutuhan Pengguna: Admin (City Official)

### Functional Requirements (FR) - Admin Layer

| ID          | Deskripsi Kebutuhan                                                                                                                                                                         | Target Implementasi (Serverless)                                                                 |
| :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| **ADM-001** | Akun admin dibuat secara khusus melalui form/metode internal terproteksi.                                                                                                                   | Firebase Auth Custom Claims (`isAdmin: true`)                                                    |
| **ADM-002** | Admin dapat melihat daftar semua laporan warga dengan status `Pending`, `In Review`, `Dispatched`, dan `In Progress` (menunggu respons).                                                    | Real-time Stream Queries pada Firestore                                                          |
| **ADM-003** | Admin dapat melakukan penolakan (`Rejected`) terhadap laporan yang tidak valid.                                                                                                             | Firestore Document Update                                                                        |
| **ADM-004** | Admin dapat menerima laporan untuk masuk ke dalam proses review (`In Review`).                                                                                                              | Firestore Document Update                                                                        |
| **ADM-005** | Admin dapat melakukan penugasan (_dispatch_) petugas lapangan melalui Form Dispatch khusus.                                                                                                 | Pembuatan dokumen baru di sub-koleksi `/dispatches`                                              |
| **ADM-006** | Admin dapat melihat seluruh komentar dari warga pada detail laporan.                                                                                                                        | Real-time Stream `/reports/{id}/comments`                                                        |
| **ADM-007** | Admin dapat memberi komentar atau membalas komentar langsung pada laporan.                                                                                                                  | Write operation ke sub-koleksi `/comments`                                                       |
| **ADM-008** | Admin memiliki hak moderasi penuh untuk membatasi atau menghapus komentar yang melanggar aturan.                                                                                            | Firestore Delete operation (Diizinkan via Security Rules)                                        |
| **ADM-009** | Admin dapat melakukan filter laporan berdasarkan 4 tingkatan lokasi (Provinsi, Kota, Desa, dan Radius Geohash berdasarkan Pin koordinat).                                                   | Gabungan Firestore compound queries & Geoflutterfire                                             |
| **ADM-010** | Admin dapat melakukan filter laporan berdasarkan Tingkat Urgensi dan Identitas Pengguna (Anonim vs Publik).                                                                                 | Firestore Query Filtering                                                                        |
| **ADM-011** | Admin dapat melihat list ajuan diri petugas pada halaman laporan.                                                                                                                           | Real-time Stream Queries pada Firestore                                                          |
| **ADM-012** | Admin dapat menerima ajuan diri petugas pada laporan.                                                                                                                                       | Firestore Document Update                                                                        |
| **ADM-013** | Admin dapat menolak ajuan diri petugas pada laporan.                                                                                                                                        | Firestore Document Update                                                                        |
| **ADM-014** | Admin dapat melihat daftar petugas lapangan yang terdaftar dengan informasi kontak dan status ketersediaan.                                                                                 | Real-time Stream Queries pada Firestore                                                          |
| **ADM-015** | Admin dapat mengelola jadwal kerja petugas lapangan, termasuk penugasan ulang jika diperlukan.                                                                                              | Firestore Document Update                                                                        |
| **ADM-016** | Admin dapat melihat statistik laporan berdasarkan status, lokasi, dan tren waktu.                                                                                                           |                                                                                                  | Firestore Aggregation Queries (via Cloud Functions)    |
| **ADM-017** | Admin dapat melihat laporan yang sudah diproses dengan status `Resolved` atau `Rejected` untuk keperluan audit dan evaluasi.                                                                | Real-time Stream Queries pada Firestore                                                          |
|             | **ADM-018**                                                                                                                                                                                 | Admin dapat mengakses halaman profil untuk mengubah informasi pribadi dan preferensi notifikasi. | Firebase Auth User Management & Firestore User Profile |
| **ADM-019** | Admin dapat melakukan pemblokiran (ban/suspend) terhadap akun warga yang terbukti melakukan spam laporan palsu. (Tambahan)Cloud Functions (Update Firebase Auth status & Firestore status)  | Firestore Update pada koleksi global /settings/categories                                        |
| **ADM-020** | Admin dapat mengelola kategori pelaporan infrastruktur (menambah, menonaktifkan kategori seperti Jalan, Drainase, dll). (Tambahan)Firestore Update pada koleksi global /settings/categories | Firestore Update pada koleksi global /settings/categories                                        |

> Note Implementasi: Beberapa kebutuhan tergantung pada implementasi pada role petugas lapangan dan warga.

> Note Dispatch: Proses dispatch pemilihan petugas lapangan berdasarkan jarak dan ketersediaan petugas yang terdaftar di database, dengan logika pemilihan yang dijalankan pada Cloud Function untuk memastikan keadilan dan efisiensi penugasan.

### Notification & Background Requirements (FR-N)

| ID            | Deskripsi Pemicu Notifikasi                                                                                                | Logika Sistem (Serverless)                             |
| :------------ | :------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------- |
| **NOTIF-001** | Mendapat notifikasi instan ketika ada laporan baru masuk dari warga.                                                       | Cloud Function `onCreate` di koleksi `/reports` -> FCM |
| **NOTIF-002** | Mendapat notifikasi ketika ada update status dari petugas lapangan di lokasi.                                              | Cloud Function `onUpdate` di dokumen dispatch -> FCM   |
| **NOTIF-003** | Mendapat notifikasi pengingat otomatis jika ada laporan yang tidak direspons dalam jangka waktu tertentu (misal > 48 jam). | Cloud Functions Scheduled Trigger (Cron Job harian)    |

### Aturan Privasi & Keamanan Data (Business Rule Data)

- **BR-ADM-001 (Presentation Anonymity):** Laporan yang ditandai sebagai "Anonim" oleh warga hanya disembunyikan identitasnya pada _Presentation Layer_ (Antarmuka Flutter). _Data Layer_ (Firestore) tetap menyimpan `reporterId` asli untuk kebutuhan relasi data, audit sistem, dan pengiriman push notification target ke pengirim asli ketika status laporan berubah.

### Page Content & UI/UX Notes

- **Admin Dashboard:**:
  - Halaman utama dengan ringkasan statistik laporan (jumlah laporan per status, grafik tren laporan, dll).
  - Minimap Heatmap untuk visualisasi konsentrasi laporan berdasarkan lokasi geografis.
  - Shortcut untuk filter laporan berdasarkan status, tingkat urgensi. Pada laporan yang belum diproses.
  - Detail laporan dengan informasi lengkap, foto, komentar warga, dan tombol aksi (Accept, Reject). Note tombol accept merubah status laporan menjadi `In review` dan merubah tombol accept menjadi dispatch yang mengarah pada form dispatch untuk memilih petugas lapangan yang akan ditugaskan.
  - Fitur moderasi komentar dengan opsi untuk menghapus komentar yang tidak sesuai pada halaman detail laporan.
  - Notifikasi real-time untuk laporan baru dan update status laporan yang sedang diproses.

- **Admin Laporan:**:
  - Detail laporan dengan informasi lengkap, foto, komentar warga, dan tombol aksi (Accept, Reject). Note tombol accept merubah status laporan menjadi `In review` dan merubah tombol accept menjadi dispatch yang mengarah pada form dispatch untuk memilih petugas lapangan yang akan ditugaskan.
  - Fitur untuk melihat riwayat komentar dan interaksi terkait laporan tersebut.
  - Opsi untuk menambahkan catatan internal yang hanya dapat dilihat oleh admin lain (tidak terlihat oleh warga).

- **Admin Peta:**:
  - Tampilan peta interaktif dengan marker untuk setiap laporan yang masuk, berwarna berdasarkan status laporan (misal: merah untuk Pending, kuning untuk In Review, hijau untuk Resolved).
  - Fitur filter lokasi berdasarkan radius geohash dan tingkatan wilayah (Provinsi, Kota, Desa).
  - Opsi untuk mengklik marker dan langsung melihat detail laporan serta opsi aksi (Accept, Reject, Dispatch).

- **Admin Petugas:**:
  - Daftar petugas lapangan yang terdaftar dengan informasi kontak dan status ketersediaan.
  - Halaman khusus untuk melihat ajuan diri petugas pada laporan tertentu, dengan opsi untuk menerima atau menolak ajuan tersebut.
  - Fitur untuk mengelola jadwal kerja petugas lapangan, termasuk penugasan ulang jika diperlukan.

- **Admin Profile:**:
  - Halaman profil admin dengan informasi pribadi dan opsi untuk mengubah password.
  - Fitur untuk mengelola preferensi notifikasi dan pengaturan akun.

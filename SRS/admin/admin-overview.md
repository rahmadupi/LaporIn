## 2.1 Kebutuhan Pengguna: Admin (City Official)

### Functional Requirements (FR) - Admin Layer

| ID          | Deskripsi Kebutuhan                                                                                                                                                                         | Target Implementasi (Serverless)                                                                 |
| :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| **ADM-001** | Akun admin dibuat secara khusus melalui form/metode internal terproteksi.                                                                                                                   | Firebase Auth Custom Claims (`isAdmin: true`)                                                    |
| **ADM-002** | Admin dapat melihat daftar semua laporan warga dengan status `Pending`, `In Review`, `Dispatched`, dan `In Progress` (menunggu respons).                                                    | Real-time Stream Queries pada Firestore                                                          |
| **ADM-003** | Admin dapat melakukan penolakan (`Rejected`) terhadap laporan yang tidak valid.                                                                                                             | Firestore Document Update                                                                        |
| **ADM-004** | Admin dapat menerima laporan untuk masuk ke dalam proses review (`In Review`).                                                                                                              | Firestore Document Update                                                                        |
| **ADM-005** | Admin dapat melakukan penugasan (_dispatch_) petugas lapangan melalui Form Dispatch khusus.                                                                                                 | Pembuatan dokumen baru di sub-koleksi `/dispatches`                                              |
| **ADM-006** | _(REMOVED — public comment system dropped. See [`feature/comment_moderation.md`](./feature/comment_moderation.md).)_                                                                        | —                                                                                                |
| **ADM-007** | _(REMOVED — see comment_moderation.md.)_                                                                                                                                                    | —                                                                                                |
| **ADM-008** | _(REMOVED — see comment_moderation.md.)_                                                                                                                                                    | —                                                                                                |
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
| **ADM-021** | Admin dapat Log Out dari akun admin.                                                                                                                                                        | Firebase Auth Sign Out + Clear Local Storage                                                     |
| **ADM-022** | Admin dapat menghapus (delete) akun admin sendiri.                                                                                                                                          | Firebase Auth Account Delete + Firestore User Profile Delete                                     |
| **ADM-023** | _(REMOVED — banding/appeal workflow dropped. See [`feature/report_moderation.md`](./feature/report_moderation.md).)_                                                                        | —                                                                                                |
| **ADM-024** | _(REMOVED — see report_moderation.md.)_                                                                                                                                                     | —                                                                                                |
| **ADM-025** | Admin dapat melihat daftar pengguna yang diblokir (banned).                                                                                                                                 | Firestore Query `where("status", "==", "banned")`                                                |
| **ADM-026** | Admin dapat melakukan unbanned (membuka blokir) pengguna yang sebelumnya diblokir.                                                                                                          | Firestore Document Update `status: "active"`                                                     |

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

- **BR-ADM-002 (Role-Based Access Control):**
  - **Admin:** Hanya dapat moderate report, assign officer, manage users (ban/unban/approve), manage categories, view analytics. Admin TIDAK dapat membuat report atau bertindak sebagai officer.
  - **Officer:** Hanya dapat melihat dan mengerjakan dispatch yang ditugaskan, update status laporan, upload bukti perbaikan.
  - **Citizen:** Hanya dapat membuat report dan melihat status laporan milik sendiri.

### Aturan Keamanan per Role (Security Rules)

| Action                | Admin    | Officer  | Citizen  |
| --------------------- | -------- | -------- | -------- |
| Membuat laporan       | ❌ Tidak | ❌ Tidak | ✅ Ya    |
| Accept/Reject laporan | ✅ Ya    | ❌ Tidak | ❌ Tidak |
| Dispatch officer      | ✅ Ya    | ❌ Tidak | ❌ Tidak |
| Menerima dispatch     | ❌ Tidak | ✅ Ya    | ❌ Tidak |
| Ban / Unban user      | ✅ Ya    | ❌ Tidak | ❌ Tidak |
| Approve officer       | ✅ Ya    | ❌ Tidak | ❌ Tidak |
| View analytics        | ✅ Ya    | ❌ Tidak | ❌ Tidak |
| Manage categories     | ✅ Ya    | ❌ Tidak | ❌ Tidak |

### Page Content & UI/UX Notes

- **Admin Dashboard:** (lihat [`feature/dashboard_analytics.md`](./feature/dashboard_analytics.md)):
  - **Stat Cards (2×2):** Laporan Masuk · Laporan Diverifikasi · Pengguna Aktif · Petugas Aktif (semua via Firestore `getCountFromServer()`).
  - **Priority Alerts ("Perlu Perhatian Anda"):** 4 tier dengan **threshold tetap**, deskripsi = **overview generik** (bukan alasan/instruksi) —
    - 🔴 **KRITIS** — `pending` + `urgencyLevel = "critical"` + `createdAt < now - 1h` — _"Permasalahan sangat besar pada keselamatan publik"_
    - 🟠 **TINGGI** — `in_progress` + `urgencyLevel = "high"` + `dispatchedAt < now - 36h` (75% dari SLA 48h) — _"Permasalahan besar pada lingkungan dan keselamatan"_
    - 🟡 **SEDANG** — `in_review` + `urgencyLevel = "medium"` + `updatedAt < now - 24h` — _"Permasalahan sedang pada infrastruktur"_
    - 🟢 **RENDAH** — `pending` + `urgencyLevel = "low"` + `createdAt < now - 24h` — _"Permasalahan ringan"_
  - Tap priority row → masuk ke **Moderasi → Laporan** dengan filter chip + urgency sudah ter-applied.
  - Shortcut ke **Moderasi → Pengguna** untuk ban/unban, approval officer, reaktivasi akun dormant (lihat [`feature/user_moderation.md`](./feature/user_moderation.md)).
  - Detail laporan mengikuti spec di [`feature/report_detail_page.md`](./feature/report_detail_page.md) — hero image, status roadmap, lokasi, deskripsi, **Penyelesaian**, dan bottom action bar `[ Tolak ] [ Terima ]` (Terima → Dispatch Form).
  - Status dapat diubah melalui dropdown di samping badge status (lihat [`feature/report_status_management.md`](./feature/report_status_management.md)).
  - Notifikasi real-time untuk laporan baru dan update status laporan yang sedang diproses.

- **Admin Moderasi (Laporan + Pengguna):**:
  Halaman Moderasi memiliki **2 sub-page** yang diakses via tab switcher di bagian atas:

  #### Sub-page 1: Laporan (lihat [`feature/report_moderation.md`](./feature/report_moderation.md))
  - **Detailed list** dengan baris yang cukup besar untuk menampilkan ringkasan laporan + tombol **Accept** dan **Reject** inline ketika status = `pending`.
  - Filter chips: `Semua`, `Menunggu`, `Diproses`, `Selesai`, `Ditolak`. Filter tambahan: urgensi, anonimitas, radius geohash.
  - Tap baris (di luar tombol) → membuka [Detail Laporan](./feature/report_detail_page.md).
  - Tombol **Accept** pada baris `pending` → set status `in_review` + membuka **Dispatch Form** (officer picker).
  - Tombol **Reject** pada baris `pending` → Reject Dialog (isi `rejectComment`, opsional `duplicateOfId`).
  - **Tidak ada** alur banding/appeal lagi — sudah dihapus.
  - **Tidak ada** komentar publik / catatan internal — sudah dihapus (lihat [`feature/comment_moderation.md`](./feature/comment_moderation.md)).

  #### Sub-page 2: Pengguna (lihat [`feature/user_moderation.md`](./feature/user_moderation.md))
  - Empat tab internal: **Aktif**, **Diblokir**, **Persetujuan**, **Dormant**.
  - **Aktif**: daftar user aktif, tombol **Ban** dengan dialog alasan.
  - **Diblokir**: daftar user banned, tombol **Unban**.
  - **Persetujuan**: officer dengan `status: "pending"`, tombol **Setujui** / **Tolak**.
  - **Dormant**: akun `inActive`, tombol **Reactivate**.

- **Admin Peta:**:
  - Tampilan peta interaktif dengan marker untuk setiap laporan yang masuk, berwarna berdasarkan status laporan (misal: merah untuk Pending, kuning untuk In Review, hijau untuk Resolved).
  - **Fitur Filter:**
    - Filter berdasarkan **status** laporan (Pending, In Review, Dispatched, In Progress, Resolved, Rejected).
    - Filter berdasarkan **kategori** (Jalan, Drainase, Penerangan, dll.).
    - Filter berdasarkan **district/wilayah** (Provinsi, Kota, Desa).
    - Filter berdasarkan **radius geohash** (distance from a point).
    - Filter berdasarkan **tingkat urgensi** (Darurat, Biasa, Rendah).
    - Filter berdasarkan **range tanggal** (tanggal laporan masuk).
  - **Search:** Pencarian laporan berdasarkan judul atau alamat.
  - Opsi untuk mengklik marker dan langsung melihat detail laporan serta opsi aksi (Accept, Reject, Dispatch).

- **Admin Petugas:**:
  Halaman manajemen petugas lapangan dengan **3 sub-page** yang dapat diakses via tab/bottom navigation dalam section Petugas:

  #### Sub-page 1: Daftar Petugas (Officer List)
  - Daftar seluruh petugas lapangan yang terdaftar dengan informasi kontak dan status ketersediaan (`isAvailable`).
  - **Filter**: berdasarkan status ketersediaan (Tersedia/Sedang Tugas), district, dan skill/keahlian.
  - **Search**: pencarian berdasarkan nama atau nomor HP.
  - **Kartu petugas**: menampilkan nama, photo, district, jumlah tugas aktif, rating (jika ada), status online/offline.
  - Aksi per petugas: lihat profil lengkap, ubah status ketersediaan, reassign tugas.

  #### Sub-page 2: Persetujuan (Pending Approval)
  - Daftar officer yang **berstatus `status: "pending"`** — akun yang mendaftar tetapi belum disetujui admin.
  - Setiap kartu menampilkan: nama, email, nomor HP, tanggal pendaftaran, daerah asal.
  - Aksi per officer:
    - **"Setujui"** → `status: "active"`, `approvedBy: adminId`, `approvedAt: Timestamp` → officer dapat login.
    - **"Tolak"** → akun dihapus dari Firebase Auth + Firestore, atau ditandai `status: "banned"` dengan `banReason` berisi alasan penolakan.
  - Notifikasi FCM dikirim ke officer saat persetujuan ditolak.

  #### Sub-page 3: Permintaan Tugas (Officer Task Requests)
  - Daftar ajuan diri officer yang **meminta untuk ditugaskan** pada laporan tertentu.
  - Setiap item menampilkan: nama officer, laporan yang diminta (judul + lokasi), timestamp ajuan, status.
  - Aksi per ajuan:
    - **"Terima"** → membuka **Form Dispatch** dengan field **Officer pre-filled** (dari officer yang meminta) + data laporan. Admin tinggal konfirmasi atau ubah jika perlu.
    - **"Tolak"** → status ajuan diubah ke `rejected`, officer mendapat notifikasi penolakan.
  - Filter: berdasarkan status ajuan (pending/accepted/rejected), district, tanggal.
  - Search: pencarian berdasarkan nama officer atau judul laporan.

- **Admin Profile:**:
  - Halaman profil admin dengan informasi pribadi dan opsi untuk mengubah password.
  - Fitur untuk mengelola preferensi notifikasi dan pengaturan akun.
  - opsi untuk menghapus akun
  - opsi untuk mengatur nama pengguna

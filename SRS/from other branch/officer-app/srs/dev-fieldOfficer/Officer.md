# Software Requirements Specification (SRS) - Dokumentasi Integrasi Firebase

Dokumen ini berisi spesifikasi perancangan data dan integrasi Cloud Firestore / Firebase Services pada komponen **Field Officer (Relawan)**.

---

## Daftar Komunikasi Database per File

### 1. `officer_login_screen.dart`
* **Fitur:** Autentikasi Akun & Pengecekan Hak Akses
* **Layanan Firebase:** Firebase Authentication & Cloud Firestore
* **Koleksi / Path:** `users/{uid}`
* **Tipe Aksi:** `Read / Auth`
* **Daftar Field yang Digunakan:**
  * `email` (String)
  * `password` (String)

---

### 2. `officer_home_screen.dart`
* **Fitur:** Profil Header, Real-Time Tugas Beranda, Lapor Darurat GPS, & Pop-Up Notifikasi Lonceng
* **Layanan Firebase:** Cloud Firestore
* **Koleksi / Path:** `users/User1` dan `assignments`
* **Tipe Aksi:** `Read`, `Write (Create)`, `Read Real-Time (Stream)`, `Delete`
* **Daftar Field yang Digunakan:**
  * **Path `users/User1` (Read):**
    * `name` (String)
    * `role` (String)
  * **Path `assignments` (Write / Create via FAB Lapor Darurat):**
    * `title` (String)
    * `location` (String)
    * `latitude` (Double) — *dari sensor GPS*
    * `longitude` (Double) — *dari sensor GPS*
    * `urgency` (String) — *default: "Mendesak"*
    * `status` (String) — *default: "Belum Dimulai"*
    * `description` (String)
    * `created_at` (Timestamp)
  * **Path `assignments` (Read Real-Time & Query Filter):**
    * Kondisi Beranda: `.where('status', isNotEqualTo: 'Selesai')`
    * Kondisi Lonceng Notifikasi: `.where('status', isEqualTo: 'Belum Dimulai')`
  * **Path `assignments/{id}` (Delete via Dismissible):**
    * `.delete()` berdasarkan ID dokumen untuk membatalkan tugas.

---

### 3. `officer_map_screen.dart`
* **Fitur:** Peta Sebaran Lokasi Tugas Aktif (OpenStreetMap)
* **Layanan Firebase:** Cloud Firestore
* **Koleksi / Path:** `assignments`
* **Tipe Aksi:** `Read Real-Time (Stream)`
* **Query Filter:** `.where('status', isNotEqualTo: 'Selesai')`
* **Daftar Field yang Digunakan:**
  * `title` (String)
  * `latitude` (Double)
  * `longitude` (Double)
  * `status` (String)

---

### 4. `officer_task_detail_screen.dart`
* **Fitur:** Manajemen Status Pengambilan Tugas Lapangan
* **Layanan Firebase:** Cloud Firestore
* **Koleksi / Path:** `assignments/{document_id}`
* **Tipe Aksi:** `Update`
* **Daftar Field yang Diperbarui:**
  * `status` (String) — *berubah dari "Belum Dimulai" menjadi "Sedang Dikerjakan"*

---

### 5. `officer_proof_screen.dart`
* **Fitur:** Unggah Bukti Lapangan & Penyelesaian Tugas
* **Layanan Firebase:** ImgBB API & Cloud Firestore
* **Koleksi / Path:** `assignments/{document_id}`
* **Tipe Aksi:** `Update`
* **Daftar Field yang Digunakan:**
  * `status` (String) — *diperbarui menjadi "Selesai"*
  * `completion_notes` (String) — *catatan pekerjaan*
  * `photo_before_url` (String) — *tautan URL ImgBB foto sebelum*
  * `photo_after_url` (String) — *tautan URL ImgBB foto sesudah*
  * `completed_at` (Timestamp)

---

### 6. `officer_history_screen.dart`
* **Fitur:** Menampilkan Daftar Riwayat Pekerjaan Selesai
* **Layanan Firebase:** Cloud Firestore
* **Koleksi / Path:** `assignments`
* **Tipe Aksi:** `Read (Get / Stream)`
* **Query Filter:** `.where('status', isEqualTo: 'Selesai')`
* **Daftar Field yang Digunakan:**
  * `title` (String)
  * `location` (String)
  * `status` (String)

---

### 7. `officer_profile_screen.dart`
* **Fitur:** Detail Informasi Biodata Akun Petugas & Statistik Kinerja
* **Layanan Firebase:** Cloud Firestore
* **Koleksi / Path:** `users/User1`
* **Tipe Aksi:** `Read (Get)`
* **Daftar Field yang Digunakan:**
  * `name` (String)
  * `role` (String)
  * `completed_tasks` (Number/String) — *untuk menampilkan statistik tugas selesai*
  * `rating` (Number/String) — *untuk menampilkan statistik rating bintang relawan*
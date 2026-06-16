# Fitur Citizen (Warga) — LaporIn

Semua fitur di bawah memakai **data nyata Firestore/Storage** — tidak ada dummy
data di layar produksi.

## Autentikasi

- **Login** (`login_screen`) & **Register** (`register_screen`) via Firebase
  Auth email/password. Saat register, profil ditulis ke `users/{uid}`.
- **Reset password** (`forgot_password_screen`).
- **Logout** dari Profil → memutus sesi + membuang FCM token perangkat ini.
- Setelah login/registrasi/pemulihan sesi, **FCM token disimpan** ke
  `users/{uid}.fcmTokens`.

## Navigasi

`CitizenMainNavigation`: BottomAppBar 4 tab — **Beranda, Peta, Watch Zones,
Profil** — + FAB **Lapor** di tengah.

## Reports (CRUD penuh)

| Operasi | Detail |
|---|---|
| **Create** | Alur 5 langkah: kategori → foto → lokasi (GPS+alamat) → deskripsi → pratinjau. Foto diunggah ke Storage `reports/{id}/photo.jpg`; bila write Firestore gagal, foto yatim dihapus (rollback). |
| **Read** | Riwayat (`report_history_screen`) stream laporan milik user, kecuali yang soft-deleted. Detail (`report_detail_screen`) real-time. Beranda & Peta membaca laporan publik. |
| **Update** | Ubah deskripsi selama status `pending`; divalidasi ulang di server lewat Firestore transaction. |
| **Delete** | **Soft delete**: `isDeleted=true` + `deletedAt` server timestamp (dokumen tetap untuk audit). Hanya saat status `pending`. |

Validasi field wajib: kategori, foto, lokasi (lat/lng), alamat, deskripsi.
Semua timestamp memakai `FieldValue.serverTimestamp()`.

## Peta (External API)

- `map_screen` menampilkan laporan publik sebagai marker berwarna status.
- Chip filter kategori (Semua/Jalan/Lampu/Sampah/Drainase) menyaring marker.
- Tap marker → kartu pratinjau → tap kartu → **Detail Laporan**.
- Peta tahan-banting: tetap dirender walau API key Maps belum dipasang.

## Notifikasi (CRUD)

- **Push (FCM)**: izin diminta; token disimpan; handler foreground (banner
  in-app), background, dan terminated; deep link ke detail bila ada `reportId`.
- **Notification Center** (`notification_screen`) membaca koleksi
  `notifications` (stream: `userId == uid`, `isDeleted == false`, terbaru dulu).
  - **Read**: daftar notifikasi + empty/loading/error state.
  - **Update**: tandai satu dibaca (tap) & "Tandai Semua Dibaca".
  - **Delete**: geser kartu → soft delete (`isDeleted=true`, `deletedAt`).
  - Tap notifikasi ber-`reportId` → buka Detail Laporan + tandai dibaca.

## Watch Zones (CRUD penuh — Firestore)

Koleksi `watch_zones`. `watch_zone_list_screen` + `watch_zone_screen`.

| Operasi | Detail |
|---|---|
| **Create** | Geser peta untuk pilih pusat, isi nama, atur radius; alamat di-reverse-geocode lalu dokumen dibuat. |
| **Read** | Daftar zona milik user (stream), dengan subtitle radius + alamat. Pratinjau editor menampilkan **jumlah laporan aktif nyata** dalam radius. |
| **Update** | Tap kartu → editor terisi → simpan memperbarui dokumen. |
| **Delete** | Geser kartu → soft delete (`isDeleted=true`, `deletedAt`). |

> Watch Zone adalah fitur **yang sudah diimplementasikan penuh** (bukan
> placeholder). Pengiriman push otomatis saat ada laporan baru dalam zona
> direncanakan via Cloud Function di rilis berikutnya (di luar cakupan client).

## Beranda & Profil

- **Beranda**: sapaan nama user, statistik **nyata** (laporan aktif, selesai,
  jumlah watch zone), daftar "Laporan Terdekat" (publik), ringkasan watch zone.
- **Profil**: nama & email dari akun login, statistik nyata (total laporan,
  selesai, watch zones), menu Notifikasi/Riwayat/Tentang/Keluar.

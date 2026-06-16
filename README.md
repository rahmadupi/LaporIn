# LaporIn — Sarana Laporan Infrastruktur Publik

LaporIn adalah aplikasi mobile (Flutter) untuk menampung laporan keresahan
publik dari warga: kerusakan jalan, lampu jalan mati, drainase tersumbat,
sampah, banjir, dan fasilitas umum lain. Repo ini berfokus pada **peran Citizen
(warga)** yang sudah siap untuk evaluasi Final Project dan persiapan rilis Play
Store.

> Kode aplikasi ada di folder [`app/`](app/). Jalankan semua perintah Flutter
> dari dalam folder `app/`.

## Peran Citizen (Warga)

Warga dapat:

- **Login / Register** akun (Firebase Authentication, email & password).
- **Membuat laporan**: pilih kategori → ambil foto → pin lokasi (GPS + alamat)
  → isi deskripsi → kirim.
- **Melihat riwayat & detail** laporan miliknya (real-time).
- **Mengubah deskripsi** laporan selama status masih `pending`.
- **Menghapus (soft delete)** laporan miliknya.
- **Peta**: melihat laporan publik di sekitar sebagai marker berwarna status.
- **Watch Zones**: membuat/mengedit/menghapus area pantauan (CRUD Firestore).
- **Notifikasi**: menerima push (FCM) & membaca Notification Center (Firestore),
  menandai dibaca, dan menghapus notifikasi.
- **Navigasi bawah** 4 tab (Beranda, Peta, Watch Zones, Profil) + FAB "Lapor".

Rincian lengkap: [`docs/CITIZEN_FEATURES.md`](docs/CITIZEN_FEATURES.md).

## Pemenuhan syarat Final Project

| Syarat | Implementasi di LaporIn |
|---|---|
| Firebase Authentication | Email/password (`firebase_auth`) — login, register, reset, logout. |
| Cloud Firestore | Koleksi `users`, `reports`, `ratings`, `notifications`, `watch_zones`. |
| Full CRUD | **Reports**, **Notifications**, dan **Watch Zones** semuanya Create/Read/Update/Delete (soft delete). |
| Push Notifications | Firebase Cloud Messaging: token disimpan ke `users/{uid}.fcmTokens`, handler foreground/background/terminated, deep link ke detail laporan. |
| Navigation Bar | `CitizenMainNavigation` — BottomAppBar 4 tab + FAB. |
| External API | Google Maps (peta) + reverse geocoding (`geocoding`) untuk koordinat→alamat. |
| SDG alignment | SDG 11 & SDG 16 (lihat di bawah). |
| Tanpa dummy data | Semua layar produksi membaca data nyata dari Firestore (lihat audit di bawah). |
| Tanpa konfigurasi palsu | Maps API key dari `local.properties` (tidak di-commit); tidak ada `YOUR_..._HERE` di source. |
| Struktur siap Play Store | Lihat [`docs/PLAY_STORE_CHECKLIST.md`](docs/PLAY_STORE_CHECKLIST.md). |

## Arsitektur singkat

Clean-ish layering per fitur: `domain/` (entitas + kontrak repository),
`data/` (model Firestore + implementasi repository), `presentation/`
(provider/notifier + screen + widget). UI tidak pernah meng-import SDK Firebase
langsung — semua lewat repository (dependency injection via `provider`).

Backend yang dipakai **hanya Firebase** (Auth, Firestore, Storage, Messaging).
Tidak ada Supabase.

## Teknologi

- **Firebase Authentication** — identitas warga.
- **Cloud Firestore** — penyimpanan laporan, notifikasi, watch zone, profil.
- **Firebase Storage** — foto laporan (`reports/{reportId}/photo.jpg`).
- **Firebase Cloud Messaging** — push notification + deep link.
- **Google Maps + Geocoding** — peta laporan & konversi koordinat→alamat.

## SDG alignment

- **SDG 11 — Kota & Permukiman Berkelanjutan**: LaporIn mempermudah warga
  melaporkan kerusakan infrastruktur publik dan ruang publik yang tidak aman,
  sehingga perbaikan bisa lebih cepat ditindaklanjuti.
- **SDG 16 — Perdamaian, Keadilan & Kelembagaan Tangguh**: setiap laporan
  memakai soft delete + timestamp server (audit trail) sehingga riwayat
  penanganan transparan dan akuntabel.

## Cara menjalankan

```bash
cd app
flutter pub get

# Salin contoh lalu isi Google Maps API key Anda (file ini di-gitignore):
cp android/local.properties.example android/local.properties
#   lalu set MAPS_API_KEY=... di android/local.properties

flutter run            # debug (peta tetap aman walau key kosong)
flutter analyze        # static analysis (harus "No issues found!")
```

Setup penuh (Firebase, Maps, rules, FCM) ada di folder [`docs/`](docs/):

- [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md)
- [`docs/GOOGLE_MAPS_SETUP.md`](docs/GOOGLE_MAPS_SETUP.md)
- [`docs/PLAY_STORE_CHECKLIST.md`](docs/PLAY_STORE_CHECKLIST.md)
- [`docs/CITIZEN_FEATURES.md`](docs/CITIZEN_FEATURES.md)
- [`docs/DATA_COLLECTED.md`](docs/DATA_COLLECTED.md)

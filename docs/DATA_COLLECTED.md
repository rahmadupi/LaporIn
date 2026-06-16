# Data yang Dikumpulkan — LaporIn (Citizen)

Dokumen ini adalah **dasar penyusunan kebijakan privasi & Data safety form**
Play Console. Ini **bukan** kebijakan privasi resmi — tim wajib menyusun
kebijakan privasi nyata sebelum rilis.

| Data | Dari mana | Disimpan di | Tujuan |
|---|---|---|---|
| Email | Input saat register/login | Firebase Auth + `users/{uid}.email` | Autentikasi & identitas akun. |
| Nama tampilan, no. telepon | Input saat register | `users/{uid}` | Profil & kontak. |
| Deskripsi laporan | Input saat membuat laporan | `reports/{id}.description` | Konten laporan. |
| Foto laporan | Kamera/galeri (image_picker) | Firebase Storage `reports/{id}/photo.jpg` | Bukti visual kerusakan. |
| Koordinat lokasi (lat/lng) | GPS (geolocator) | `reports/{id}.location`, `watch_zones/{id}` | Menandai lokasi laporan & area pantauan. |
| Alamat | Reverse geocoding (Geocoding API) | `reports/{id}.address`, `watch_zones/{id}.address` | Alamat keterbacaan manusia. |
| FCM token | Firebase Messaging | `users/{uid}.fcmTokens` | Mengirim push notification ke perangkat. |
| Waktu (createdAt/updatedAt/lastLoginAt) | Server timestamp | berbagai koleksi | Audit & pengurutan. |

## Izin runtime terkait

- **Lokasi** (`ACCESS_FINE/COARSE_LOCATION`) — pin lokasi laporan & watch zone.
- **Kamera** (`CAMERA`) — mengambil foto kerusakan.
- **Notifikasi** (`POST_NOTIFICATIONS`, Android 13+) — push FCM.
- **Internet** (`INTERNET`) — komunikasi dengan Firebase.

## Penghapusan data

Laporan, notifikasi, dan watch zone memakai **soft delete** (ditandai
`isDeleted`, tidak dihapus fisik) untuk menjaga jejak audit. Untuk permintaan
penghapusan akun/data permanen, sediakan kanal kontak pada kebijakan privasi.

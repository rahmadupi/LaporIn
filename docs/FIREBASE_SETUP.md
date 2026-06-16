# Setup Firebase — LaporIn

Semua perintah dijalankan dari folder `app/` (tempat `firebase.json` berada).

## 1. Buat / buka project Firebase

1. Buka <https://console.firebase.google.com>.
2. Project yang dipakai repo ini: **`laporin-7c61e`** (lihat `app/firebase.json`).
   Untuk project sendiri, klik **Add project** dan ikuti wizard.

## 2. Daftarkan aplikasi Android

1. Di Firebase Console → ikon Android (**Add app**).
2. **Android package name** harus sama dengan `applicationId` di
   `app/android/app/build.gradle.kts` — saat ini **`com.example.main`**.
   > Sebelum rilis Play Store, ganti ke domain milik tim (mis.
   > `id.laporin.app`) lalu **daftarkan ulang** app di Firebase agar
   > `google-services.json` cocok.
3. (Opsional) Tambahkan SHA-1 / SHA-256 (lihat GOOGLE_MAPS_SETUP untuk cara ambil SHA-1).

## 3. Unduh & letakkan `google-services.json`

1. Unduh `google-services.json` dari halaman app Android.
2. Letakkan di: **`app/android/app/google-services.json`**.
3. Plugin `com.google.gms.google-services` (sudah aktif di Gradle) akan membacanya.

> File `firebase_options.dart` (Dart) sudah ada di repo. Jika Anda memakai
> project Firebase sendiri, regen dengan FlutterFire CLI:
> `dart pub global activate flutterfire_cli && flutterfire configure`.

## 4. Aktifkan Email/Password Authentication

Firebase Console → **Authentication** → **Get started** → tab **Sign-in method**
→ aktifkan **Email/Password** → Save.

## 5. Buat database Cloud Firestore

1. Console → **Firestore Database** → **Create database**.
2. Pilih lokasi (mis. `asia-southeast2`), mulai dalam **Production mode**.
3. Koleksi dibuat otomatis oleh aplikasi saat data pertama ditulis:
   `users`, `reports`, `ratings`, `notifications`, `watch_zones`.

## 6. Aktifkan Firebase Storage

Console → **Storage** → **Get started** → terima lokasi default. Foto laporan
disimpan di `reports/{reportId}/photo.jpg`.

## 7. Aktifkan Cloud Messaging (FCM)

Console → **Project settings** → **Cloud Messaging** → pastikan API aktif.
Aplikasi sudah:

- meminta izin notifikasi (Android 13+ butuh `POST_NOTIFICATIONS`),
- mengambil FCM token & menyimpannya ke `users/{uid}.fcmTokens` (array),
- memperbarui token via `onTokenRefresh`, dan menghapusnya saat logout,
- menangani pesan foreground (banner in-app), background, dan terminated,
- deep link ke detail laporan bila payload memuat `reportId`.

## 8. Deploy Firestore & Storage rules

Rules ada di repo: `app/firestore.rules`, `app/storage.rules`,
indeks di `app/firestore.indexes.json`.

```bash
cd app
npm install -g firebase-tools     # sekali saja
firebase login
firebase use laporin-7c61e        # atau project Anda

# Deploy rules + indeks:
firebase deploy --only firestore:rules,firestore:indexes,storage
```

> Jika kueri riwayat/notifikasi error "requires an index", Firestore memberi
> link pembuatan index otomatis di log — atau cukup deploy `firestore:indexes`.

## 9. Tes FCM dari Firebase Console

1. Jalankan app di perangkat, login → token tersimpan otomatis
   (cek `users/{uid}.fcmTokens` di Firestore, dan log `[FCM] Token tersimpan`).
2. Console → **Messaging** → **Create your first campaign** → **Firebase
   Notification messages**.
3. Isi judul & teks → **Send test message** → tempel salah satu FCM token →
   **Test**.
4. **Deep link (opsional)**: pada bagian **Additional options → Custom data**,
   tambahkan key `reportId` dengan value salah satu ID laporan (mis.
   `LPR-2026-0001234`). Saat notifikasi diketuk, app membuka detail laporan itu.

### Membuat notifikasi in-app (Notification Center)

Notification Center membaca koleksi `notifications`. Dokumen biasanya ditulis
oleh backend/Cloud Function saat status laporan berubah. Untuk demo manual,
tambahkan dokumen di koleksi `notifications` dengan field:

```
userId: <uid warga>      (string)
title: "Status Laporan Diperbarui"
message: "Laporan Anda sedang ditinjau."
type: "status_update"    (status_update | completed | assignment | info)
reportId: "LPR-2026-0001234"   (opsional; tap membuka detail)
isRead: false
isDeleted: false
createdAt: <timestamp>   (server timestamp)
```

# Checklist Persiapan Play Store — LaporIn

Status saat ini disetel agar aman untuk **pengembangan & demo**. Item bertanda
⚠️ harus diselesaikan **sebelum** rilis produksi ke Play Console.

## Identitas aplikasi

- [ ] ⚠️ **Package name / applicationId**: saat ini `com.example.main`
  (`app/android/app/build.gradle.kts`). Ganti ke domain milik tim (mis.
  `id.laporin.app`) lalu daftarkan ulang app di Firebase & perbarui
  `google-services.json` (lihat FIREBASE_SETUP).
- [ ] ⚠️ **Nama aplikasi**: `android:label="main"` di AndroidManifest →
  ganti jadi `LaporIn`.
- [ ] ⚠️ **Ikon**: ganti `@mipmap/ic_launcher` dengan ikon brand LaporIn
  (gunakan `flutter_launcher_icons` atau Android Studio Asset Studio).

## SDK & signing

- [x] `minSdk = 23` (disyaratkan Firebase Auth/Firestore terbaru).
- [x] `targetSdk` mengikuti `flutter.targetSdkVersion` (terbaru dari Flutter).
- [ ] ⚠️ **Keystore rilis**: buat keystore & `key.properties` (sudah
  di-gitignore). Lihat <https://flutter.dev/to/reference-keystore>.
- [ ] ⚠️ **signingConfig release**: saat ini memakai **debug key** agar
  `flutter run --release` jalan selama dev (lihat `buildTypes { release }`).
  Ganti ke `signingConfig` keystore rilis sebelum mem-build AAB produksi.

## Build

- [ ] Set `MAPS_API_KEY` (release **gagal** tanpa key — lihat GOOGLE_MAPS_SETUP).
- [ ] `flutter build appbundle --release` sukses.
- [ ] Uji APK/AAB rilis di **perangkat fisik** (peta, kamera, lokasi, notifikasi).

## Kualitas & keamanan

- [x] **Tidak ada dummy data** di layar produksi Citizen (lihat audit di
  CITIZEN_FEATURES & README).
- [x] **Tidak ada placeholder API key** di source (key dari `local.properties`).
- [ ] **Deploy Firestore & Storage rules** (`firebase deploy --only
  firestore:rules,firestore:indexes,storage`).
- [ ] (Opsional) Kurangi `debugPrint` yang verbose — saat ini dipakai untuk
  diagnostik FCM/Firestore; otomatis tidak tampil di pengguna akhir, tapi bisa
  dibersihkan untuk rilis final.

## Izin Android

Hanya izin yang benar-benar dipakai (lihat AndroidManifest):

- [x] `INTERNET` — Firebase.
- [x] `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — pin lokasi laporan & watch zone.
- [x] `CAMERA` — ambil foto kerusakan (image_picker).
- [x] `POST_NOTIFICATIONS` — push FCM (Android 13+).

## Privasi

- [ ] ⚠️ **Kebijakan privasi** wajib di Play Console karena app mengakses
  **lokasi, kamera, storage, dan notifikasi**. Jangan memalsukan dokumen ini —
  susun kebijakan nyata. Data yang dikumpulkan terdaftar di
  [`DATA_COLLECTED.md`](DATA_COLLECTED.md) sebagai dasar penyusunan.
- [ ] Isi **Data safety form** di Play Console sesuai `DATA_COLLECTED.md`.

## Google Maps metadata

- [x] `com.google.android.geo.API_KEY` di-inject dari Gradle (tidak hardcoded).
- [ ] API key dibatasi ke package name + SHA-1 (debug & release).

# Setup Google Maps & Geocoding — LaporIn

LaporIn memakai **External API**: Google Maps SDK for Android (menampilkan peta
laporan & watch zone) dan **Geocoding API** (reverse geocoding koordinat→alamat).

## Cara kerja API key (aman untuk di-commit)

- AndroidManifest **tidak** memuat key mentah. Manifest membaca
  `${MAPS_API_KEY}` dari Gradle `manifestPlaceholders`.
- Gradle (`app/android/app/build.gradle.kts`) membaca `MAPS_API_KEY` dari
  `android/local.properties` **atau** flag `-PMAPS_API_KEY=...` (untuk CI).
- `local.properties` sudah **di-gitignore** → key asli tidak pernah masuk repo.
- Build **release** akan **gagal cepat** bila `MAPS_API_KEY` kosong (mencegah
  rilis dengan peta kosong). Build **debug** tetap jalan (hanya peringatan),
  sehingga developer lain bisa menjalankan app tanpa key.

## 1. Buka Google Cloud Console

<https://console.cloud.google.com> → pilih project yang **sama** dengan project
Firebase (`laporin-7c61e`) agar billing & kuota menyatu.

## 2. Aktifkan API

**APIs & Services → Library** → aktifkan:

- **Maps SDK for Android** (wajib — menampilkan peta).
- **Geocoding API** (wajib — koordinat→alamat di Step 3 & Watch Zone).

> Maps SDK biasanya butuh **billing account** aktif (ada kuota gratis bulanan).

## 3. Buat API key

**APIs & Services → Credentials → Create credentials → API key**. Salin key.

## 4. Batasi API key (penting untuk keamanan)

Klik key → **Edit**:

- **Application restrictions** → **Android apps** → **Add**:
  - **Package name**: `com.example.main` (atau applicationId final Anda).
  - **SHA-1**: dari keystore debug & release.
- **API restrictions** → **Restrict key** → centang hanya:
  **Maps SDK for Android** dan **Geocoding API**.

### Mengambil SHA-1

```bash
# Debug (untuk pengembangan):
cd app/android
./gradlew signingReport            # Windows: gradlew.bat signingReport
# Cari baris "SHA1:" pada variant debug.
```

Untuk **release**, ambil SHA-1 dari keystore rilis:

```bash
keytool -list -v -keystore <path-keystore-rilis>.jks -alias <alias>
```

Tambahkan SHA-1 debug **dan** release ke daftar Android apps pada key.

## 5. Tambahkan key ke `local.properties`

```bash
cd app
cp android/local.properties.example android/local.properties
```

Edit `android/local.properties`, isi satu baris:

```
MAPS_API_KEY=AIza...key-asli-anda...
```

## 6. Konfigurasi build release

- Pastikan SHA-1 keystore rilis sudah terdaftar pada API key (langkah 4).
- Untuk CI tanpa `local.properties`, lewatkan key via flag:

  ```bash
  flutter build appbundle --release -PMAPS_API_KEY=AIza...key...
  ```

- Tanpa key, `flutter build apk/appbundle --release` akan **gagal dengan pesan
  jelas** (lihat `build.gradle.kts`).

## 7. Verifikasi

`flutter run`, buka tab **Peta** → tile peta tampil. Buka **Lapor → Step 3**,
pin lokasi → alamat hasil reverse geocoding muncul di kartu alamat.

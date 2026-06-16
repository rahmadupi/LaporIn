import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Mengaktifkan Google Services untuk Firebase (membaca google-services.json).
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Google Maps API key ──────────────────────────────────────────────────
// Key TIDAK pernah di-commit. Dibaca saat build dari local.properties (kunci
// `MAPS_API_KEY`) atau dari flag `-PMAPS_API_KEY=...` (mis. di CI). Lihat
// android/app/local.properties.example & docs/GOOGLE_MAPS_SETUP.md.
val mapsApiKey: String = run {
    val fromProject = project.findProperty("MAPS_API_KEY") as String?
    if (!fromProject.isNullOrBlank()) return@run fromProject.trim()
    val localProps = Properties()
    val localFile = rootProject.file("local.properties")
    if (localFile.exists()) {
        localFile.inputStream().use { localProps.load(it) }
    }
    (localProps.getProperty("MAPS_API_KEY") ?: "").trim()
}

android {
    namespace = "com.example.main"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Catatan Play Store: applicationId masih `com.example.main` agar cocok
        // dengan google-services.json yang sudah terdaftar. Sebelum rilis ke
        // Play, ganti ke domain milik tim & daftarkan ulang aplikasi di Firebase
        // (lihat docs/PLAY_STORE_CHECKLIST.md).
        applicationId = "com.example.main"
        // Firebase Auth/Firestore SDK terbaru mensyaratkan minSdk 23.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Diinjeksi ke AndroidManifest sebagai ${MAPS_API_KEY}. Tidak ada key
        // mentah di manifest sehingga aman di-commit.
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // TODO produksi: ganti dengan signingConfig rilis (keystore tim).
            // Saat ini memakai debug key agar `flutter run --release` tetap jalan
            // selama pengembangan (lihat docs/PLAY_STORE_CHECKLIST.md).
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Gagal cepat & jelas bila build RELEASE dijalankan tanpa MAPS_API_KEY, agar
// APK/AAB produksi tidak terlanjur rilis dengan peta kosong. Build debug tetap
// boleh tanpa key (hanya peringatan) supaya developer lain bisa menjalankan app.
gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any {
        it.name.contains("Release", ignoreCase = true) &&
            (it.name.startsWith("assemble") || it.name.startsWith("bundle"))
    }
    if (mapsApiKey.isBlank()) {
        if (buildingRelease) {
            throw GradleException(
                "MAPS_API_KEY belum diset. Tambahkan 'MAPS_API_KEY=...' ke " +
                    "android/local.properties atau jalankan dengan " +
                    "-PMAPS_API_KEY=... sebelum build release. " +
                    "Lihat docs/GOOGLE_MAPS_SETUP.md."
            )
        } else {
            logger.warn(
                "[LaporIn] MAPS_API_KEY kosong — peta akan tampil kosong " +
                    "(build debug tetap berjalan). Lihat docs/GOOGLE_MAPS_SETUP.md."
            )
        }
    }
}

flutter {
    source = "../.."
}

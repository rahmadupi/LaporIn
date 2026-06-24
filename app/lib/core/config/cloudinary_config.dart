import 'package:flutter/foundation.dart';

/// Konfigurasi Cloudinary — image storage pengganti Firebase Storage.
///
/// `cloudName` dan `uploadPreset` BUKAN rahasia:
///   * cloud name memang publik (muncul di setiap URL gambar), dan
///   * unsigned upload preset sengaja dirancang untuk dipakai dari klien.
/// Jadi aman ditaruh di sini untuk keperluan development. JANGAN PERNAH menaruh
/// **API Secret** di aplikasi — unsigned upload tidak membutuhkannya.
///
/// Dua cara mengisi (pilih salah satu):
///   1. Edit langsung nilai `defaultValue` di bawah, ATAU
///   2. Override saat run tanpa menyentuh source (lebih aman bila repo publik):
///        flutter run \
///          --dart-define=CLOUDINARY_CLOUD_NAME=nama_cloud_anda \
///          --dart-define=CLOUDINARY_UPLOAD_PRESET=nama_preset_anda
class CloudinaryConfig {
  const CloudinaryConfig._();

  /// Nama cloud akun Cloudinary (Dashboard → "Cloud name").
  static const String cloudName =
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'dyaes58ee');

  /// Nama unsigned upload preset (Settings → Upload → Upload presets).
  static const String uploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: 'LaporIn');

  /// True bila kedua nilai sudah diisi. Dipakai service untuk gagal cepat dengan
  /// pesan jelas alih-alih menembak endpoint Cloudinary tanpa kredensial.
  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  /// Cetak peringatan (DEBUG saja) bila kredensial belum diisi, supaya developer
  /// langsung sadar upload foto laporan akan gagal. TIDAK melempar — app tetap
  /// berjalan normal (graceful). Dipanggil saat fase inisialisasi (Splash).
  static void debugWarnIfUnconfigured() {
    if (kDebugMode && !isConfigured) {
      debugPrint(
        '[Cloudinary] PERINGATAN: cloudName/uploadPreset masih kosong. '
        'Upload foto laporan akan gagal sampai diisi di '
        'lib/core/config/cloudinary_config.dart atau via --dart-define '
        '(CLOUDINARY_CLOUD_NAME / CLOUDINARY_UPLOAD_PRESET).',
      );
    }
  }
}

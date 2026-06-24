/// Exception domain untuk kegagalan pada fitur laporan.
///
/// Sama seperti AuthFailure di fitur auth: UI cukup menangkap [ReportFailure]
/// dan menampilkan [message] berbahasa Indonesia, tanpa perlu tahu apakah
/// kegagalan berasal dari Cloudinary, Firestore, atau jaringan.
class ReportFailure implements Exception {
  const ReportFailure(this.message);

  final String message;

  /// Gagal saat mengunggah foto ke Cloudinary (penyebab jaringan/umum).
  factory ReportFailure.photoUpload() => const ReportFailure(
        'Gagal mengunggah foto. Periksa koneksi lalu coba lagi.',
      );

  /// Foto tidak valid / tidak dapat dibaca dari penyimpanan perangkat.
  factory ReportFailure.photoInvalid() => const ReportFailure(
        'Foto tidak valid. Ambil atau pilih ulang foto.',
      );

  /// Ukuran foto melebihi batas yang diizinkan (10 MB).
  factory ReportFailure.photoTooLarge() => const ReportFailure(
        'Ukuran foto terlalu besar (maks 10 MB). Coba foto lain.',
      );

  /// Tidak punya izin mengunggah (sesi habis / preset Cloudinary menolak).
  factory ReportFailure.unauthorized() => const ReportFailure(
        'Sesi tidak sah untuk mengunggah. Silakan login ulang.',
      );

  /// Kegagalan jaringan saat menghubungi server.
  factory ReportFailure.network() => const ReportFailure(
        'Koneksi bermasalah. Periksa internet lalu coba lagi.',
      );

  /// Gagal saat menyimpan dokumen laporan ke Firestore.
  factory ReportFailure.firestoreWrite() => const ReportFailure(
        'Foto terunggah, tetapi data laporan gagal disimpan. Coba lagi.',
      );

  /// Fallback untuk error tak terduga.
  factory ReportFailure.unexpected() => const ReportFailure(
        'Terjadi kesalahan saat mengirim laporan. Silakan coba lagi.',
      );

  /// Operasi edit/hapus ditolak karena laporan sudah diproses (bukan `pending`).
  factory ReportFailure.notEditable() => const ReportFailure(
        'Laporan tidak dapat diubah karena sudah diproses.',
      );

  /// Laporan tidak ditemukan (mis. sudah dihapus dari sumber).
  factory ReportFailure.notFound() => const ReportFailure(
        'Laporan tidak ditemukan.',
      );

  /// Gagal menyimpan perubahan (edit/hapus) ke Firestore.
  factory ReportFailure.saveFailed() => const ReportFailure(
        'Gagal menyimpan perubahan. Periksa koneksi lalu coba lagi.',
      );

  @override
  String toString() => message;
}

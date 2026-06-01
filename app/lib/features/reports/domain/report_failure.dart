/// Exception domain untuk kegagalan pada fitur laporan.
///
/// Sama seperti AuthFailure di fitur auth: UI cukup menangkap [ReportFailure]
/// dan menampilkan [message] berbahasa Indonesia, tanpa perlu tahu apakah
/// kegagalan berasal dari Storage, Firestore, atau jaringan.
class ReportFailure implements Exception {
  const ReportFailure(this.message);

  final String message;

  /// Gagal saat mengunggah foto ke Firebase Storage.
  factory ReportFailure.photoUpload() => const ReportFailure(
        'Gagal mengunggah foto. Periksa koneksi lalu coba lagi.',
      );

  /// Gagal saat menyimpan dokumen laporan ke Firestore.
  factory ReportFailure.firestoreWrite() => const ReportFailure(
        'Foto terunggah, tetapi data laporan gagal disimpan. Coba lagi.',
      );

  /// Fallback untuk error tak terduga.
  factory ReportFailure.unexpected() => const ReportFailure(
        'Terjadi kesalahan saat mengirim laporan. Silakan coba lagi.',
      );

  @override
  String toString() => message;
}

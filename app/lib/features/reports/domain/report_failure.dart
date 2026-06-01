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

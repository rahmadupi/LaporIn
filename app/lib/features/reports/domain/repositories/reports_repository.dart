import 'dart:io';

import '../entities/report_category.dart';
import '../entities/report_severity.dart';

/// Kontrak (interface) operasi penyimpanan laporan.
///
/// Layer presentation (ReportFormNotifier) hanya bergantung pada abstraksi ini,
/// bukan pada Firebase langsung (NFR-6). Implementasi konkret ada di
/// FirebaseReportsRepository.
abstract class ReportsRepository {
  /// Membuat laporan baru secara end-to-end (FR-2.1):
  ///   1. Mengunggah [photo] ke Firebase Storage `/reports/{reportId}/photo.jpg`.
  ///   2. Menulis dokumen ke koleksi `reports` di Firestore.
  ///
  /// Mengembalikan `reportId` (format `LPR-YYYY-NNNNNNN`) untuk dijadikan
  /// nomor tiket di Success Screen. Melempar [ReportFailure] bila gagal.
  ///
  /// [reporterId] sudah final saat sampai sini: UID asli bila publik, atau
  /// `anonymous_<hash>` bila [isAnonymous] true — repository tidak perlu tahu
  /// asal-usulnya (logika anonimisasi ada di ReportFormNotifier, FR-2.2).
  Future<String> createReport({
    required String reporterId,
    required bool isAnonymous,
    required ReportCategory category,
    required File photo,
    required double latitude,
    required double longitude,
    required String address,
    required String description,
    required ReportSeverity severity,
  });
}

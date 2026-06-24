import 'report_category.dart';
import 'report_severity.dart';
import 'report_status.dart';

/// Entitas laporan yang dibaca dari Firestore (read model).
///
/// Berbeda dari payload tulis (ReportModel.toFirestore) yang dipakai saat
/// membuat laporan: entitas ini "bersih" dari tipe Firebase (GeoPoint, Timestamp
/// sudah dikonversi ke tipe Dart) agar UI & notifier tidak perlu menyentuh SDK.
class Report {
  const Report({
    required this.reportId,
    required this.displayId,
    required this.reporterId,
    required this.isAnonymous,
    required this.category,
    required this.description,
    required this.severity,
    required this.photoUrls,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
  });

  /// ID dokumen Firestore (auto-generated). Sumber kebenaran untuk semua
  /// operasi CRUD/navigasi (watchReport, softDelete, dll) & key marker peta.
  final String reportId;

  /// Nomor tiket tampilan `LPR-YYYY-NNNNNNN` (skema 8.2). HANYA untuk
  /// ditampilkan ke pengguna — JANGAN dipakai sebagai ID dokumen (tidak dijamin
  /// unik karena dibuat acak di klien).
  final String displayId;

  final String reporterId;
  final bool isAnonymous;
  final ReportCategory category;
  final String description;
  final ReportSeverity severity;
  final List<String> photoUrls;
  final double latitude;
  final double longitude;
  final String address;
  final ReportStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  /// Foto Before/After diisi petugas saat penyelesaian (Anggota C). Per skema
  /// aslinya tersimpan di koleksi `assignments`; agar Detail Citizen bisa
  /// menampilkannya tanpa join lintas-koleksi, flow penyelesaian diharapkan
  /// men-denormalisasi URL-nya ke dokumen report. Nullable + ditangani aman
  /// bila belum tersedia.
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;

  /// Foto utama (pertama) untuk thumbnail/hero; null bila belum ada.
  String? get primaryPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;
}

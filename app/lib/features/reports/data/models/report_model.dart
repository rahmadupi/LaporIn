import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/geohash.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_category.dart';
import '../../domain/entities/report_severity.dart';
import '../../domain/entities/report_status.dart';

/// Pembuat payload Firestore untuk koleksi `reports`.
///
/// Menyendirikan logika serialisasi di sini menjaga repository tetap fokus pada
/// orkestrasi (upload + write), dan menjaga skema (bagian 8.2 dokumen) berada
/// di satu tempat agar mudah diaudit.
class ReportModel {
  ReportModel._();

  /// Mem-parsing satu dokumen Firestore menjadi entitas domain [Report].
  ///
  /// Konversi tipe Firebase -> Dart dilakukan di sini: GeoPoint -> double
  /// lat/lng, Timestamp -> DateTime. Pakai akses defensif (null-aware + default)
  /// agar dokumen lama/tak lengkap tidak membuat parsing crash.
  static Report fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final geo = data['location'] as GeoPoint?;
    final photos = (data['photoUrls'] as List?)?.cast<String>() ?? const [];

    return Report(
      // Pakai field reportId bila ada, jika tidak pakai id dokumen.
      reportId: (data['reportId'] as String?) ?? doc.id,
      reporterId: (data['reporterId'] as String?) ?? '',
      isAnonymous: (data['isAnonymous'] as bool?) ?? false,
      category: ReportCategory.fromSlug(data['category'] as String?),
      description: (data['description'] as String?) ?? '',
      severity: ReportSeverity.fromSlug(data['severity'] as String?),
      photoUrls: photos,
      latitude: geo?.latitude ?? 0,
      longitude: geo?.longitude ?? 0,
      address: (data['address'] as String?) ?? '',
      status: ReportStatus.fromSlug(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      // Denormalisasi opsional dari flow penyelesaian (lihat entitas Report).
      beforePhotoUrl: data['beforePhotoUrl'] as String?,
      afterPhotoUrl: data['afterPhotoUrl'] as String?,
    );
  }

  /// Menyusun map sesuai skema `reports/{reportId}`.
  ///
  /// Field `geohash` dihitung dari koordinat agar laporan bisa di-query secara
  /// geografis (deteksi duplikat / Watch Zones). `status` selalu `pending`
  /// untuk laporan baru — alur verifikasi mengubahnya belakangan.
  static Map<String, dynamic> toFirestore({
    required String reportId,
    required String reporterId,
    required bool isAnonymous,
    required ReportCategory category,
    required List<String> photoUrls,
    required double latitude,
    required double longitude,
    required String address,
    required String description,
    required ReportSeverity severity,
  }) {
    return {
      'reportId': reportId,
      'reporterId': reporterId,
      'isAnonymous': isAnonymous,
      'category': category.slug,
      'description': description,
      'severity': severity.slug,
      'photoUrls': photoUrls,
      // GeoPoint adalah tipe asli Firestore untuk koordinat (bisa di-query).
      'location': GeoPoint(latitude, longitude),
      'address': address,
      'geohash': Geohash.encode(latitude, longitude),
      'status': 'pending',
      'assignmentId': null,
      'rejectionReason': null,
      // serverTimestamp memakai jam server Firebase, bukan jam device.
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
      'isDeleted': false,
      'deletedAt': null,
    };
  }
}

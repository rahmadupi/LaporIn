import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/geohash.dart';
import '../../domain/entities/report_category.dart';
import '../../domain/entities/report_severity.dart';

/// Pembuat payload Firestore untuk koleksi `reports`.
///
/// Menyendirikan logika serialisasi di sini menjaga repository tetap fokus pada
/// orkestrasi (upload + write), dan menjaga skema (bagian 8.2 dokumen) berada
/// di satu tempat agar mudah diaudit.
class ReportModel {
  ReportModel._();

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

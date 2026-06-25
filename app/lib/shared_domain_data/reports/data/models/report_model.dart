import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/report_entity.dart';

/// Konversi antara Firestore DocumentSnapshot dan ReportEntity.
///
/// Skema baru mengikuti snippet referensi:
///   - `displayId`        (String?)
///   - `category`         (String slug)
///   - `severity`         (low | medium | high | critical)
///   - `photos`           (List<String>) — alias untuk `photoUrls`
///   - `geo`              (GeoPoint)
///   - `address`          (String, flat)
///   - `resolvedAt`       (Timestamp)
///   - `beforePhotoUrl`   (String?)
///   - `afterPhotoUrl`    (String?)
///
/// Untuk backward compatibility, parser juga menerima bentuk lama
/// (`imageUrls`, `urgencyLevel`, `location` map, `addressDetails`).
class ReportModel {
  static ReportEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // --- displayId: displayId → reportId → doc.id ---
    final displayId =
        (data['displayId'] as String?) ??
        (data['reportId'] as String?) ??
        doc.id;

    // --- photos: dukung `photos`, `photoUrls`, dan `imageUrls` ---
    final photosRaw = data['photos'] ?? data['photoUrls'] ?? data['imageUrls'];
    final photos =
        (photosRaw as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const <String>[];

    // --- geo: dukung `geo` (GeoPoint) dan `location` (map) ---
    GeoPoint? geo;
    final rawGeo = data['geo'];
    if (rawGeo is GeoPoint) {
      geo = rawGeo;
    } else if (rawGeo is Map) {
      final lat = (rawGeo['latitude'] as num?)?.toDouble();
      final lng = (rawGeo['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) geo = GeoPoint(lat, lng);
    } else {
      final loc = data['location'];
      if (loc is Map) {
        final lat = (loc['latitude'] as num?)?.toDouble();
        final lng = (loc['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) geo = GeoPoint(lat, lng);
      }
    }

    // --- address: dukung `address` (flat) dan `addressDetail` + addressDetails ---
    String address = (data['address'] as String?) ?? '';
    if (address.isEmpty) {
      final ad = data['addressDetail'] as String?;
      final details = data['addressDetails'] as Map<String, dynamic>?;
      final parts = <String>[];
      if (ad != null && ad.isNotEmpty) parts.add(ad);
      if (details != null) {
        if (details['district'] != null) {
          parts.add(details['district'].toString());
        }
        if (details['city'] != null) parts.add(details['city'].toString());
        if (details['province'] != null) {
          parts.add(details['province'].toString());
        }
      }
      address = parts.join(', ');
    }

    // --- severity: dukung `severity` dan `urgencyLevel` ---
    final severityRaw =
        (data['severity'] as String?) ?? (data['urgencyLevel'] as String?);

    return ReportEntity(
      reportId: doc.id,
      displayId: displayId,
      reporterId: (data['reporterId'] as String?) ?? '',
      isAnonymous: (data['isAnonymous'] as bool?) ?? false,
      description: (data['description'] as String?) ?? '',
      category: ReportCategory.fromSlug(data['category'] as String?),
      severity: ReportSeverity.fromSlug(severityRaw),
      photoUrls: photos,
      beforePhotoUrl: data['beforePhotoUrl'] as String?,
      afterPhotoUrl: data['afterPhotoUrl'] as String?,
      latitude: geo?.latitude ?? 0,
      longitude: geo?.longitude ?? 0,
      address: address,
      status: ReportStatus.fromSlug(data['status'] as String?),
      assignedOfficerId: data['assignedOfficerId'] as String?,
      dispatchedAt: (data['dispatchedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serialize ReportEntity ke Map untuk Firestore (skema baru).
  static Map<String, dynamic> toFirestore(ReportEntity report) {
    return {
      'reportId': report.reportId,
      'displayId': report.displayId.isNotEmpty
          ? report.displayId
          : report.reportId,
      'reporterId': report.reporterId,
      'isAnonymous': report.isAnonymous,
      'description': report.description,
      'category': report.category.slug,
      if (report.rejectComment != null) 'rejectComment': report.rejectComment,
      'appealRequested': report.appealRequested,
      if (report.appealReason != null) 'appealReason': report.appealReason,
      if (report.appealAt != null)
        'appealAt': Timestamp.fromDate(report.appealAt!),
      if (report.duplicateOfId != null) 'duplicateOfId': report.duplicateOfId,
      'severity': report.severity.value,
      'status': report.status.value,
      if (report.photoUrls.isNotEmpty) 'photos': report.photoUrls,
      if (report.beforePhotoUrl != null)
        'beforePhotoUrl': report.beforePhotoUrl,
      if (report.afterPhotoUrl != null) 'afterPhotoUrl': report.afterPhotoUrl,
      'geo': GeoPoint(report.latitude, report.longitude),
      'address': report.address,
      if (report.assignedOfficerId != null)
        'assignedOfficerId': report.assignedOfficerId,
      if (report.dispatchedAt != null)
        'dispatchedAt': Timestamp.fromDate(report.dispatchedAt!),
      if (report.resolvedAt != null)
        'resolvedAt': Timestamp.fromDate(report.resolvedAt!),
      'createdAt': Timestamp.fromDate(report.createdAt),
      'updatedAt': Timestamp.fromDate(report.updatedAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/report_entity.dart';

/// Konversi antara Firestore DocumentSnapshot dan ReportEntity.
class ReportModel {
  /// Parse dokumen Firestore ke ReportEntity.
  static ReportEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>?;
    final addressDetails = data['addressDetails'] as Map<String, dynamic>?;
    final imageUrls =
        (data['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    return ReportEntity(
      reportId: data['reportId'] ?? doc.id,
      reporterId: data['reporterId'] ?? '',
      isAnonymous: data['isAnonymous'] ?? false,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      categoryId: data['categoryId'],
      rejectComment: data['rejectComment'],
      appealRequested: data['appealRequested'] ?? false,
      appealReason: data['appealReason'],
      appealAt: (data['appealAt'] as Timestamp?)?.toDate(),
      duplicateOfId: data['duplicateOfId'],
      urgencyLevel: ReportUrgency.fromString(data['urgencyLevel']),
      status: ReportStatus.fromString(data['status']),
      imageUrl: data['imageUrl'],
      imageUrls: imageUrls,
      latitude: (location?['latitude'] as num?)?.toDouble(),
      longitude: (location?['longitude'] as num?)?.toDouble(),
      geohash: location?['geohash'] as String?,
      province: addressDetails?['province'] as String?,
      city: addressDetails?['city'] as String?,
      district: addressDetails?['district'] as String?,
      addressDetail: data['addressDetail'] as String?,
      assignedOfficerId: data['assignedOfficerId'],
      dispatchedAt: (data['dispatchedAt'] as Timestamp?)?.toDate(),
      proofUrl: data['proofUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serialize ReportEntity ke Map untuk Firestore.
  static Map<String, dynamic> toFirestore(ReportEntity report) {
    return {
      'reportId': report.reportId,
      'reporterId': report.reporterId,
      'isAnonymous': report.isAnonymous,
      'title': report.title,
      'description': report.description,
      if (report.categoryId != null) 'categoryId': report.categoryId,
      if (report.rejectComment != null) 'rejectComment': report.rejectComment,
      'appealRequested': report.appealRequested,
      if (report.appealReason != null) 'appealReason': report.appealReason,
      if (report.appealAt != null)
        'appealAt': Timestamp.fromDate(report.appealAt!),
      if (report.duplicateOfId != null) 'duplicateOfId': report.duplicateOfId,
      'urgencyLevel': report.urgencyLevel.value,
      'status': report.status.value,
      if (report.imageUrl != null) 'imageUrl': report.imageUrl,
      if (report.imageUrls.isNotEmpty) 'imageUrls': report.imageUrls,
      if (report.latitude != null && report.longitude != null)
        'location': {
          'latitude': report.latitude,
          'longitude': report.longitude,
          if (report.geohash != null) 'geohash': report.geohash,
        },
      if (report.province != null ||
          report.city != null ||
          report.district != null)
        'addressDetails': {
          if (report.province != null) 'province': report.province,
          if (report.city != null) 'city': report.city,
          if (report.district != null) 'district': report.district,
        },
      if (report.addressDetail != null) 'addressDetail': report.addressDetail,
      if (report.assignedOfficerId != null)
        'assignedOfficerId': report.assignedOfficerId,
      if (report.dispatchedAt != null)
        'dispatchedAt': Timestamp.fromDate(report.dispatchedAt!),
      if (report.proofUrl != null) 'proofUrl': report.proofUrl,
      'createdAt': Timestamp.fromDate(report.createdAt),
      'updatedAt': Timestamp.fromDate(report.updatedAt),
    };
  }
}

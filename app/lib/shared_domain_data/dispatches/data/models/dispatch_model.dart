import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/dispatch_entity.dart';

/// Konversi antara Firestore DocumentSnapshot dan DispatchEntity.
class DispatchModel {
  /// Parse dokumen Firestore ke DispatchEntity.
  static DispatchEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DispatchEntity(
      dispatchId: data['dispatchId'] ?? doc.id,
      reportId: data['reportId'] ?? '',
      officerId: data['officerId'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      status: DispatchStatus.fromString(data['status']),
      resolutionNotes: data['resolutionNotes'] as String?,
      resolutionImageUrl: data['resolutionImageUrl'] as String?,
      assignedAt:
          (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Serialize DispatchEntity ke Map untuk Firestore.
  static Map<String, dynamic> toFirestore(DispatchEntity dispatch) {
    return {
      'dispatchId': dispatch.dispatchId,
      'reportId': dispatch.reportId,
      'officerId': dispatch.officerId,
      'assignedBy': dispatch.assignedBy,
      'status': dispatch.status.value,
      if (dispatch.resolutionNotes != null)
        'resolutionNotes': dispatch.resolutionNotes,
      if (dispatch.resolutionImageUrl != null)
        'resolutionImageUrl': dispatch.resolutionImageUrl,
      'assignedAt': Timestamp.fromDate(dispatch.assignedAt),
      if (dispatch.completedAt != null)
        'completedAt': Timestamp.fromDate(dispatch.completedAt!),
    };
  }
}

/// Model untuk entri officer self-request di
/// `/reports/{reportId}/officer/{officerId}`.
///
/// Lihat [SRS data-model.md §3.2.2](../../../../../../../SRS/data-model.md).
class OfficerSelfRequestModel {
  /// Parse dokumen sub-collection officer.
  static OfficerSelfRequest fromFirestore(
    DocumentSnapshot doc, {
    required String reportId,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return OfficerSelfRequest(
      reportId: reportId,
      officerId: data['officerId'] ?? doc.id,
      officerName: data['officerName'] ?? '',
      status: data['status'] ?? 'applied',
      appliedAt: (data['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Entity ringan untuk ajuan diri officer.
class OfficerSelfRequest {
  final String reportId;
  final String officerId;
  final String officerName;
  final String status; // 'applied' | 'accepted' | 'rejected'
  final DateTime appliedAt;

  const OfficerSelfRequest({
    required this.reportId,
    required this.officerId,
    required this.officerName,
    required this.status,
    required this.appliedAt,
  });

  bool get isPending => status == 'applied';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

/// Enum untuk status laporan sesuai SRS data-model.md.
///
/// Lifecycle: pending → in_review → dispatched → in_progress → resolved
/// Plus `rejected` as an off-ramp.
enum ReportStatus {
  pending,
  inReview,
  dispatched,
  inProgress,
  resolved,
  rejected;

  String get value {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.inReview:
        return 'in_review';
      case ReportStatus.dispatched:
        return 'dispatched';
      case ReportStatus.inProgress:
        return 'in_progress';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Menunggu Verifikasi';
      case ReportStatus.inReview:
        return 'Verifikasi';
      case ReportStatus.dispatched:
        return 'Penugasan';
      case ReportStatus.inProgress:
        return 'Pengerjaan';
      case ReportStatus.resolved:
        return 'Selesai';
      case ReportStatus.rejected:
        return 'Ditolak';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReportStatus.pending:
        return 'Menunggu';
      case ReportStatus.inReview:
        return 'Verifikasi';
      case ReportStatus.dispatched:
        return 'Penugasan';
      case ReportStatus.inProgress:
        return 'Pengerjaan';
      case ReportStatus.resolved:
        return 'Selesai';
      case ReportStatus.rejected:
        return 'Ditolak';
    }
  }

  static ReportStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return ReportStatus.pending;
      case 'in_review':
        return ReportStatus.inReview;
      case 'dispatched':
        return ReportStatus.dispatched;
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.pending;
    }
  }
}

/// Enum untuk urgency level sesuai SRS data-model.md.
enum ReportUrgency {
  low,
  medium,
  high,
  critical;

  String get value {
    switch (this) {
      case ReportUrgency.low:
        return 'low';
      case ReportUrgency.medium:
        return 'medium';
      case ReportUrgency.high:
        return 'high';
      case ReportUrgency.critical:
        return 'critical';
    }
  }

  String get label {
    switch (this) {
      case ReportUrgency.low:
        return 'Rendah';
      case ReportUrgency.medium:
        return 'Sedang';
      case ReportUrgency.high:
        return 'Tinggi';
      case ReportUrgency.critical:
        return 'Kritis';
    }
  }

  static ReportUrgency fromString(String? value) {
    switch (value) {
      case 'low':
        return ReportUrgency.low;
      case 'medium':
        return ReportUrgency.medium;
      case 'high':
        return ReportUrgency.high;
      case 'critical':
        return ReportUrgency.critical;
      default:
        return ReportUrgency.medium;
    }
  }
}

/// Entity untuk data laporan sesuai SRS data-model.md (/reports/{reportId}).
class ReportEntity {
  final String reportId;
  final String reporterId;
  final bool isAnonymous;
  final String title;
  final String description;
  final String? categoryId;
  final String? rejectComment;
  final bool appealRequested;
  final String? appealReason;
  final DateTime? appealAt;
  final String? duplicateOfId;
  final ReportUrgency urgencyLevel;
  final ReportStatus status;
  final String? imageUrl;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;
  final String? geohash;
  final String? province;
  final String? city;
  final String? district;
  final String? addressDetail;
  final String? assignedOfficerId;
  final DateTime? dispatchedAt;
  final String? proofUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportEntity({
    required this.reportId,
    required this.reporterId,
    required this.isAnonymous,
    required this.title,
    required this.description,
    this.categoryId,
    this.rejectComment,
    this.appealRequested = false,
    this.appealReason,
    this.appealAt,
    this.duplicateOfId,
    this.urgencyLevel = ReportUrgency.medium,
    this.status = ReportStatus.pending,
    this.imageUrl,
    this.imageUrls = const [],
    this.latitude,
    this.longitude,
    this.geohash,
    this.province,
    this.city,
    this.district,
    this.addressDetail,
    this.assignedOfficerId,
    this.dispatchedAt,
    this.proofUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == ReportStatus.pending;
  bool get isResolved => status == ReportStatus.resolved;
  bool get isRejected => status == ReportStatus.rejected;
  bool get isInProgress =>
      status == ReportStatus.inProgress ||
      status == ReportStatus.dispatched ||
      status == ReportStatus.inReview;

  String get heroImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : (imageUrl ?? '');

  String get formattedAddress {
    final parts = <String>[];
    if (addressDetail != null && addressDetail!.isNotEmpty)
      parts.add(addressDetail!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    return parts.join(', ');
  }
}

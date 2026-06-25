/// Enum untuk status laporan sesuai SRS data-model.md §3.2.
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

  /// Parse dari string Firestore (alias `fromString`).
  static ReportStatus fromSlug(String? value) {
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

  /// Deprecated: gunakan [fromSlug].
  static ReportStatus fromString(String? value) => fromSlug(value);
}

/// Severity level — pengganti `ReportUrgency`. Nilai Firestore sama:
/// `low | medium | high | critical`.
enum ReportSeverity {
  low,
  medium,
  high,
  critical;

  String get value {
    switch (this) {
      case ReportSeverity.low:
        return 'low';
      case ReportSeverity.medium:
        return 'medium';
      case ReportSeverity.high:
        return 'high';
      case ReportSeverity.critical:
        return 'critical';
    }
  }

  String get label {
    switch (this) {
      case ReportSeverity.low:
        return 'Rendah';
      case ReportSeverity.medium:
        return 'Sedang';
      case ReportSeverity.high:
        return 'Tinggi';
      case ReportSeverity.critical:
        return 'Kritis';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReportSeverity.low:
        return 'R';
      case ReportSeverity.medium:
        return 'S';
      case ReportSeverity.high:
        return 'T';
      case ReportSeverity.critical:
        return 'K';
    }
  }

  static ReportSeverity fromSlug(String? value) {
    switch (value) {
      case 'low':
        return ReportSeverity.low;
      case 'medium':
        return ReportSeverity.medium;
      case 'high':
        return ReportSeverity.high;
      case 'critical':
        return ReportSeverity.critical;
      default:
        return ReportSeverity.medium;
    }
  }

  /// Deprecated: gunakan [fromSlug].
  static ReportSeverity fromString(String? value) => fromSlug(value);
}

/// Alias lama untuk backward compatibility.
typedef ReportUrgency = ReportSeverity;

/// Category slug — disimpan sebagai string di Firestore (`data['category']`).
enum ReportCategory {
  roads('roads', 'Jalan Rusak'),
  water('water', 'Saluran Air / Drainase'),
  lighting('lighting', 'Penerangan Jalan'),
  waste('waste', 'Sampah / Kebersihan'),
  signage('signage', 'Rambu / Marka'),
  bridge('bridge', 'Jembatan'),
  publicFacility('public_facility', 'Fasilitas Umum'),
  other('other', 'Lainnya');

  const ReportCategory(this.slug, this.label);

  final String slug;
  final String label;

  static ReportCategory fromSlug(String? value) {
    if (value == null) return ReportCategory.other;
    for (final c in ReportCategory.values) {
      if (c.slug == value) return c;
    }
    return ReportCategory.other;
  }
}

/// Entity untuk data laporan sesuai SRS data-model.md (/reports/{reportId}).
///
/// Skema baru (lihat snippet referensi):
///   - `displayId`        : nomor tiket tampilan
///   - `category`         : slug kategori
///   - `severity`         : low | medium | high | critical
///   - `photoUrls`        : daftar foto (sebelum & sesudah digabung)
///   - `beforePhotoUrl`   : foto sebelum
///   - `afterPhotoUrl`    : foto sesudah
///   - `address`          : alamat flat
///   - `resolvedAt`       : timestamp ketika status = resolved
class ReportEntity {
  final String reportId;
  final String displayId;
  final String reporterId;
  final bool isAnonymous;
  final String description;
  final ReportCategory category;
  final String? rejectComment;
  final bool appealRequested;
  final String? appealReason;
  final DateTime? appealAt;
  final String? duplicateOfId;
  final ReportSeverity severity;
  final ReportStatus status;
  final List<String> photoUrls;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final double latitude;
  final double longitude;
  final String address;
  final String? assignedOfficerId;
  final DateTime? dispatchedAt;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportEntity({
    required this.reportId,
    this.displayId = '',
    required this.reporterId,
    required this.isAnonymous,
    required this.description,
    this.category = ReportCategory.other,
    this.rejectComment,
    this.appealRequested = false,
    this.appealReason,
    this.appealAt,
    this.duplicateOfId,
    this.severity = ReportSeverity.medium,
    this.status = ReportStatus.pending,
    this.photoUrls = const [],
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.latitude = 0,
    this.longitude = 0,
    this.address = '',
    this.assignedOfficerId,
    this.dispatchedAt,
    this.resolvedAt,
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

  /// Foto pertama untuk thumbnail. Prioritas: afterPhotoUrl → beforePhotoUrl → photoUrls[0].
  String get heroImageUrl {
    if (afterPhotoUrl != null && afterPhotoUrl!.isNotEmpty) {
      return afterPhotoUrl!;
    }
    if (beforePhotoUrl != null && beforePhotoUrl!.isNotEmpty) {
      return beforePhotoUrl!;
    }
    if (photoUrls.isNotEmpty) return photoUrls.first;
    return '';
  }

  /// Backward-compat getters untuk kode lama.
  List<String> get imageUrls => photoUrls;
  String? get imageUrl => heroImageUrl.isEmpty ? null : heroImageUrl;
  String get categoryLabel => category.label;
  String get severityLabel => severity.label;
  String get formattedAddress => address;

  /// Backward-compat: kode lama membaca `title`. Fallback ke 60 char description.
  String get title => description.length > 60
      ? '${description.substring(0, 60)}…'
      : description;

  String? get addressDetail => address.isEmpty ? null : address;
  String? get province => null;
  String? get city => null;
  String? get district => null;
  String? get geohash => null;
  String? get proofUrl => afterPhotoUrl ?? beforePhotoUrl;
  ReportUrgency get urgencyLevel => severity; // alias lama
}

/// Enum untuk status dispatch sesuai SRS data-model.md §3.3.
///
/// Lifecycle: dispatched → in_progress → completed
enum DispatchStatus {
  dispatched,
  inProgress,
  completed;

  String get value {
    switch (this) {
      case DispatchStatus.dispatched:
        return 'dispatched';
      case DispatchStatus.inProgress:
        return 'in_progress';
      case DispatchStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case DispatchStatus.dispatched:
        return 'Ditugaskan';
      case DispatchStatus.inProgress:
        return 'Dikerjakan';
      case DispatchStatus.completed:
        return 'Selesai';
    }
  }

  static DispatchStatus fromString(String? value) {
    switch (value) {
      case 'dispatched':
        return DispatchStatus.dispatched;
      case 'in_progress':
        return DispatchStatus.inProgress;
      case 'completed':
        return DispatchStatus.completed;
      default:
        return DispatchStatus.dispatched;
    }
  }
}

/// Entity untuk dokumen dispatch di `/dispatches/{dispatchId}`.
///
/// Lihat [SRS data-model.md §3.3](../../../../../../../SRS/data-model.md).
class DispatchEntity {
  final String dispatchId;
  final String reportId;
  final String officerId;
  final String assignedBy;
  final DispatchStatus status;
  final String? resolutionNotes;
  final String? resolutionImageUrl;
  final DateTime assignedAt;
  final DateTime? completedAt;

  const DispatchEntity({
    required this.dispatchId,
    required this.reportId,
    required this.officerId,
    required this.assignedBy,
    required this.status,
    this.resolutionNotes,
    this.resolutionImageUrl,
    required this.assignedAt,
    this.completedAt,
  });

  bool get isActive =>
      status == DispatchStatus.dispatched ||
      status == DispatchStatus.inProgress;

  bool get isCompleted => status == DispatchStatus.completed;

  DispatchEntity copyWith({
    DispatchStatus? status,
    String? resolutionNotes,
    String? resolutionImageUrl,
    DateTime? completedAt,
  }) {
    return DispatchEntity(
      dispatchId: dispatchId,
      reportId: reportId,
      officerId: officerId,
      assignedBy: assignedBy,
      status: status ?? this.status,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolutionImageUrl: resolutionImageUrl ?? this.resolutionImageUrl,
      assignedAt: assignedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

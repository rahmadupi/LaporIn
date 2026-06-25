import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/report_entity.dart';
import '../models/report_model.dart';

/// Repository untuk data laporan (Firestore).
class ReportRepository {
  final FirebaseFirestore _db;

  ReportRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  /// Stream seluruh laporan, diurutkan dari yang terbaru.
  Stream<List<ReportEntity>> streamAll() {
    return _reports
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ReportModel.fromFirestore(d)).toList(),
        );
  }

  /// Stream satu laporan.
  Stream<ReportEntity?> streamOne(String reportId) {
    return _reports
        .doc(reportId)
        .snapshots()
        .map((doc) => doc.exists ? ReportModel.fromFirestore(doc) : null);
  }

  /// Stream laporan berdasarkan status.
  Stream<List<ReportEntity>> streamByStatus(ReportStatus status) {
    return _reports
        .where('status', isEqualTo: status.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ReportModel.fromFirestore(d)).toList(),
        );
  }

  /// Count laporan dengan filter tertentu (untuk stat cards & priority alerts).
  Future<int> countReports({
    required List<String> statuses,
    DateTime? createdAfter,
    DateTime? createdBefore,
    ReportUrgency? urgency,
  }) async {
    Query<Map<String, dynamic>> query = _reports;
    if (createdAfter != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(createdAfter),
      );
    }
    if (createdBefore != null) {
      query = query.where(
        'createdAt',
        isLessThan: Timestamp.fromDate(createdBefore),
      );
    }
    if (urgency != null) {
      query = query.where('urgencyLevel', isEqualTo: urgency.value);
    }
    if (statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }
    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  /// Count KRITIS: pending + critical urgency + older than [olderThan].
  Future<int> countKritis(DateTime olderThan) {
    return countReports(
      statuses: const ['pending'],
      urgency: ReportUrgency.critical,
      createdBefore: olderThan,
    );
  }

  /// Count TINGGI: in_progress + high urgency + dispatchedAt older than [olderThan].
  Future<int> countTinggi(DateTime olderThan) async {
    final snap = await _reports
        .where('status', isEqualTo: ReportStatus.inProgress.value)
        .where('urgencyLevel', isEqualTo: ReportUrgency.high.value)
        .where('dispatchedAt', isLessThan: Timestamp.fromDate(olderThan))
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Count SEDANG: in_review + medium urgency + updatedAt older than [olderThan].
  Future<int> countSedang(DateTime olderThan) {
    return countReports(
      statuses: const ['in_review'],
      urgency: ReportUrgency.medium,
      createdBefore: olderThan,
    );
  }

  /// Count RENDAH: pending + low urgency + createdAt older than [olderThan].
  Future<int> countRendah(DateTime olderThan) {
    return countReports(
      statuses: const ['pending'],
      urgency: ReportUrgency.low,
      createdBefore: olderThan,
    );
  }

  /// Terima laporan: set status ke in_review.
  Future<void> acceptToInReview(String reportId) async {
    await _reports.doc(reportId).update({
      'status': ReportStatus.inReview.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tolak laporan: set status ke rejected + rejectComment.
  Future<void> reject({
    required String reportId,
    required String rejectComment,
    String? duplicateOfId,
  }) async {
    final update = <String, dynamic>{
      'status': ReportStatus.rejected.value,
      'rejectComment': rejectComment,
      'appealRequested': false,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (duplicateOfId != null) {
      update['duplicateOfId'] = duplicateOfId;
    }
    await _reports.doc(reportId).update(update);
  }
}

/// Provider untuk ReportRepository.
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

/// Stream provider: seluruh laporan.
final allReportsStreamProvider = StreamProvider<List<ReportEntity>>((ref) {
  return ref.watch(reportRepositoryProvider).streamAll();
});

/// Future provider: priority alert counts.
class PriorityCounts {
  final int kritis;
  final int tinggi;
  final int sedang;
  final int rendah;

  const PriorityCounts({
    required this.kritis,
    required this.tinggi,
    required this.sedang,
    required this.rendah,
  });
}

final priorityCountsProvider = FutureProvider<PriorityCounts>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final now = DateTime.now();
  final results = await Future.wait([
    repo.countKritis(now.subtract(const Duration(hours: 1))),
    repo.countTinggi(now.subtract(const Duration(hours: 36))),
    repo.countSedang(now.subtract(const Duration(hours: 24))),
    repo.countRendah(now.subtract(const Duration(hours: 24))),
  ]);
  return PriorityCounts(
    kritis: results[0],
    tinggi: results[1],
    sedang: results[2],
    rendah: results[3],
  );
});

/// Future provider: dashboard report counts.
class DashboardReportCounts {
  final int laporanMasuk;
  final int laporanDiverifikasi;

  const DashboardReportCounts({
    required this.laporanMasuk,
    required this.laporanDiverifikasi,
  });
}

final dashboardReportCountsProvider = FutureProvider<DashboardReportCounts>((
  ref,
) async {
  final reportRepo = ref.watch(reportRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  final results = await Future.wait([
    reportRepo.countReports(
      statuses: const [
        'pending',
        'in_review',
        'dispatched',
        'in_progress',
        'resolved',
        'rejected',
      ],
      createdAfter: startOfMonth,
    ),
    reportRepo.countReports(
      statuses: const ['in_review', 'dispatched', 'in_progress', 'resolved'],
    ),
  ]);
  return DashboardReportCounts(
    laporanMasuk: results[0],
    laporanDiverifikasi: results[1],
  );
});

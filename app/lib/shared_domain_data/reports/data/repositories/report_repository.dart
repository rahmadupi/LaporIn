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

  /// Stream laporan yang ditugaskan ke officer tertentu. Default ke
  /// status aktif (`dispatched` + `in_progress`); parameter `statuses`
  /// untuk override (mis. Riwayat → `resolved` + `rejected`).
  /// Digunakan oleh Officer Home (OFC-002) dan Officer History (OFC-009).
  Stream<List<ReportEntity>> streamAssignedToOfficer(
    String officerId, {
    List<ReportStatus> statuses = const [
      ReportStatus.dispatched,
      ReportStatus.inProgress,
    ],
  }) {
    return _reports
        .where('assignedOfficerId', isEqualTo: officerId)
        .where('status', whereIn: statuses.map((s) => s.value).toList())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ReportModel.fromFirestore(d)).toList(),
        );
  }

  /// Stream seluruh laporan yang dibuat oleh satu citizen (CIT-003).
  /// Default **tidak** memfilter status — semua status ditampilkan
  /// (pending, in_review, dispatched, in_progress, resolved, rejected).
  /// Filtering dilakukan client-side via chip (lihat ReportHistoryScreen).
  Stream<List<ReportEntity>> streamByReporter(String reporterId) {
    return _reports
        .where('reporterId', isEqualTo: reporterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => ReportModel.fromFirestore(d)).toList(),
        );
  }

  /// Stream feed publik (CIT-013/CIT-014). Menampilkan laporan orang
  /// lain (exclude milik sendiri) dengan status visible (semua kecuali
  /// `rejected`). Limit default 50.
  Stream<List<ReportEntity>> streamPublicFeed({
    required String excludeReporterId,
    int limit = 50,
  }) {
    return _reports
        .where('status', whereIn: const [
          'pending',
          'in_review',
          'dispatched',
          'in_progress',
          'resolved',
        ])
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ReportModel.fromFirestore(d))
              // exclude laporan milik sendiri (BR-CIT-001: identitas
              // tetap di-mask di UI; tapi filter dilakukan di client).
              .where((e) => e.reporterId != excludeReporterId)
              .toList(),
        );
  }

  /// Buat laporan baru dari citizen (CIT-001 + CIT-002). Field ditulis
  /// mentah via Map karena `ReportModel.toFirestore` belum mendukung
  /// `addressDetails` (admin/analytics) — kita tulis via raw map agar
  /// sesuai [SRS/data-model.md §3.2].
  Future<String> createCitizenReport({
    required String reporterId,
    required String title,
    required String description,
    required String categoryId,
    required ReportUrgency urgencyLevel,
    required bool isAnonymous,
    required String imageUrl,
    String? addressDetail,
    String? province,
    String? city,
    String? district,
    required double latitude,
    required double longitude,
    String? geohash,
  }) async {
    final docRef = _reports.doc();
    final now = DateTime.now();
    final entity = ReportEntity(
      reportId: docRef.id,
      reporterId: reporterId,
      isAnonymous: isAnonymous,
      title: title,
      description: description,
      categoryId: categoryId,
      urgencyLevel: urgencyLevel,
      status: ReportStatus.pending,
      imageUrl: imageUrl,
      addressDetail: addressDetail,
      province: province,
      city: city,
      district: district,
      latitude: latitude,
      longitude: longitude,
      geohash: geohash,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set({
      ...ReportModel.toFirestore(entity),
      'addressDetails': {
        if (province != null) 'province': province,
        if (city != null) 'city': city,
        if (district != null) 'district': district,
      },
    });
    return docRef.id;
  }

  /// Soft delete laporan (CIT-007). Hanya boleh saat status `pending`.
  /// Firestore Security Rules di server-side menjadi pengaman kedua.
  Future<void> softDelete(String reportId) async {
    await _reports.doc(reportId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Edit deskripsi (CIT-008). Hanya boleh saat status `pending`.
  Future<void> updateDescription(String reportId, String description) async {
    await _reports.doc(reportId).update({
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ajukan banding (CIT-005) untuk laporan yang `rejected` dalam 24 jam.
  Future<void> submitAppeal(String reportId, String reason) async {
    await _reports.doc(reportId).update({
      'appealRequested': true,
      'appealReason': reason,
      'appealAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kirim rating (CIT-009) untuk laporan yang `resolved`. Disimpan di
  /// koleksi top-level `/ratings/{ratingId}`.
  Future<void> submitRating({
    required String reportId,
    required String reporterId,
    required int stars,
    String? comment,
  }) async {
    final ref = _db.collection('ratings').doc();
    await ref.set({
      'ratingId': ref.id,
      'reportId': reportId,
      'reporterId': reporterId,
      'stars': stars,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream kategori dari `/settings/categories` untuk dropdown di
  /// Report Flow (Step 1 — Kategori). Hanya `isActive == true`.
  Stream<List<Map<String, dynamic>>> streamActiveCategories() {
    return _db
        .collection('settings')
        .doc('categories')
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Buat laporan darurat dari officer (OFC-012). Field-field yang
  /// ditulis mengikuti ReportModel.toFirestore agar konsisten dengan
  /// laporan citizen.
  Future<String> createEmergencyReport({
    required String reporterId,
    required String title,
    String? description,
    required double latitude,
    required double longitude,
    ReportUrgency urgency = ReportUrgency.high,
  }) async {
    final docRef = _reports.doc();
    final now = DateTime.now();
    final entity = ReportEntity(
      reportId: docRef.id,
      reporterId: reporterId,
      isAnonymous: false,
      title: title,
      description: description ?? '',
      urgencyLevel: urgency,
      status: ReportStatus.pending,
      latitude: latitude,
      longitude: longitude,
      addressDetail: 'Dilaporkan oleh Petugas Lapangan',
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(ReportModel.toFirestore(entity));
    return docRef.id;
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

/// Stream provider: laporan yang ditugaskan ke officer yang sedang
/// login. `null` saat belum login. Memakai `streamAssignedToOfficer`
/// dengan default status `dispatched` + `in_progress` (OFC-002).
final myAssignedTasksProvider =
    StreamProvider.family<List<ReportEntity>, String>((ref, officerId) {
      return ref
          .watch(reportRepositoryProvider)
          .streamAssignedToOfficer(officerId);
    });

/// Stream provider: riwayat tugas officer yang sudah **selesai**
/// (`status: resolved`). Dipakai oleh Officer Riwayat (M4). Rejected
/// tidak dimasukkan — bisa ditambah di tab/filter terpisah nanti.
final myOfficerHistoryProvider =
    StreamProvider.family<List<ReportEntity>, String>((ref, officerId) {
      return ref
          .watch(reportRepositoryProvider)
          .streamAssignedToOfficer(
            officerId,
            statuses: const [ReportStatus.resolved],
          );
    });

/// Stream provider: seluruh laporan yang dibuat oleh satu citizen
/// (CIT-003). Dipakai oleh Citizen Riwayat.
final myCitizenReportsProvider =
    StreamProvider.family<List<ReportEntity>, String>((ref, reporterId) {
      return ref.watch(reportRepositoryProvider).streamByReporter(reporterId);
});

/// Stream provider: feed publik laporan orang lain (CIT-013).
/// `excludeReporterId` = current citizen UID agar laporan sendiri
/// tidak muncul (sesuai SRS — laporan sendiri tampil di Riwayat).
final publicReportsFeedProvider = StreamProvider.family<
  List<ReportEntity>,
  String
>((ref, excludeReporterId) {
  return ref
      .watch(reportRepositoryProvider)
      .streamPublicFeed(excludeReporterId: excludeReporterId);
});

/// Stream provider: kategori aktif untuk dropdown di Report Flow.
final activeCategoriesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(reportRepositoryProvider).streamActiveCategories();
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

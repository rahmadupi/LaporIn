import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/data/models/report_model.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../domain/entities/dispatch_entity.dart';
import '../models/dispatch_model.dart';

/// Composite entity: ajuan diri officer + parent report (joined).
///
/// Diperlukan karena sub-collection `/reports/{id}/officer` tidak menyimpan
/// judul/district report — admin butuh konteks lengkap untuk Terima/Tolak.
class OfficerSelfRequestWithReport {
  final OfficerSelfRequest request;
  final ReportEntity? report;

  const OfficerSelfRequestWithReport({required this.request, this.report});
}

/// Repository untuk dispatch + officer self-requests.
class DispatchRepository {
  final FirebaseFirestore _db;

  DispatchRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _dispatches =>
      _db.collection('dispatches');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  /// Stream ajuan diri officer yang masih berstatus `applied`.
  ///
  /// Menggunakan **collection-group query** pada sub-collection
  /// `/reports/*/officer` lalu melakukan **join** dengan parent report
  /// (single batched read) untuk mendapatkan judul + lokasi.
  ///
  /// Memerlukan composite index:
  ///   - Collection: `officer`
  ///   - Fields: `status` ASC, `appliedAt` DESC
  Stream<List<OfficerSelfRequestWithReport>> streamPendingSelfRequests() {
    return _db
        .collectionGroup('officer')
        .where('status', isEqualTo: 'applied')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap(_joinWithParentReport);
  }

  /// Stream ajuan diri **milik satu officer** (filter `officerId`).
  ///
  /// Dipakai oleh Officer Laporan (M5/OFC-003) untuk menentukan
  /// laporan mana yang sudah pernah di-request oleh officer tersebut
  /// (badge "Sudah Diajukan").
  ///
  /// Memerlukan composite index:
  ///   - Collection: `officer`
  ///   - Fields: `officerId` ASC, `status` ASC, `appliedAt` DESC
  Stream<List<OfficerSelfRequestWithReport>> streamMySelfRequests(
    String officerId, {
    List<String> statuses = const ['applied', 'accepted', 'rejected'],
  }) {
    return _db
        .collectionGroup('officer')
        .where('officerId', isEqualTo: officerId)
        .where('status', whereIn: statuses)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .asyncMap(_joinWithParentReport);
  }

  /// Buat ajuan diri officer (OFC-003). Menulis dokumen di
  /// `/reports/{reportId}/officer/{officerId}` dengan status `applied`.
  Future<void> submitSelfRequest({
    required String reportId,
    required String officerId,
    required String officerName,
  }) async {
    await _reports.doc(reportId).collection('officer').doc(officerId).set({
      'officerId': officerId,
      'officerName': officerName,
      'status': 'applied',
      'appliedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<OfficerSelfRequestWithReport>> _joinWithParentReport(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    if (snap.docs.isEmpty) return const [];

    final reportIds = <String>{
      for (final d in snap.docs) d.reference.parent.parent!.id,
    };

    // Firestore `whereIn` supports up to 30 items per query — paginate jika
    // perlu. Untuk v1 kita asumsikan <= 30 laporan dengan ajuan pending.
    final reportMap = <String, ReportEntity>{};
    final ids = reportIds.toList();
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final reportSnap = await _reports
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in reportSnap.docs) {
        reportMap[doc.id] = ReportModel.fromFirestore(doc);
      }
    }

    return snap.docs.map((d) {
      final reportId = d.reference.parent.parent!.id;
      return OfficerSelfRequestWithReport(
        request: OfficerSelfRequestModel.fromFirestore(d, reportId: reportId),
        report: reportMap[reportId],
      );
    }).toList();
  }

  /// Stream seluruh dispatch (untuk monitor).
  Stream<List<DispatchEntity>> streamAll() {
    return _dispatches
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => DispatchModel.fromFirestore(d)).toList(),
        );
  }

  /// Stream dispatch untuk satu officer (untuk "tugas aktif" count).
  Stream<List<DispatchEntity>> streamActiveByOfficer(String officerId) {
    return _dispatches
        .where('officerId', isEqualTo: officerId)
        .where('status', whereIn: const ['dispatched', 'in_progress'])
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => DispatchModel.fromFirestore(d)).toList(),
        );
  }

  /// Count dispatch aktif untuk satu officer (untuk OfficerCard).
  Future<int> countActiveByOfficer(String officerId) async {
    final disp = await _dispatches
        .where('officerId', isEqualTo: officerId)
        .where('status', whereIn: const ['dispatched', 'in_progress'])
        .count()
        .get();
    return disp.count ?? 0;
  }

  /// Terima ajuan diri officer: **batched write** (transaksi atomik).
  ///
  /// Menulis tiga dokumen sekaligus:
  ///   1. `/reports/{id}/officer/{officerId}` → `status: accepted`
  ///   2. `/dispatches/{newId}` → dokumen dispatch baru
  ///   3. `/reports/{id}` → `status: dispatched`, `assignedOfficerId`,
  ///      `dispatchedAt: serverTimestamp`, `updatedAt: serverTimestamp`
  ///
  /// Jika salah satu gagal, seluruh batch di-rollback oleh Firestore —
  /// tidak ada orphan dispatch atau sub-doc stuck `applied`.
  Future<String> acceptSelfRequest({
    required String reportId,
    required String officerId,
    required String assignedBy,
  }) async {
    final dispatchRef = _dispatches.doc();
    final officerSubRef = _reports
        .doc(reportId)
        .collection('officer')
        .doc(officerId);
    final reportRef = _reports.doc(reportId);

    final dispatch = DispatchEntity(
      dispatchId: dispatchRef.id,
      reportId: reportId,
      officerId: officerId,
      assignedBy: assignedBy,
      status: DispatchStatus.dispatched,
      assignedAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.update(officerSubRef, {'status': 'accepted'});
    batch.set(dispatchRef, DispatchModel.toFirestore(dispatch));
    batch.update(reportRef, {
      'status': 'dispatched',
      'assignedOfficerId': officerId,
      'dispatchedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return dispatchRef.id;
  }

  /// Tolak ajuan diri officer.
  Future<void> rejectSelfRequest({
    required String reportId,
    required String officerId,
  }) async {
    final officerSubRef = _reports
        .doc(reportId)
        .collection('officer')
        .doc(officerId);
    await officerSubRef.update({'status': 'rejected'});
  }

  /// Admin-initiated dispatch (dari tombol "Terima" di Laporan list).
  ///
  /// Berbeda dari [acceptSelfRequest] (officer pre-existing ajuan diri),
  /// method ini **tidak** memperbarui sub-doc officer — officer hanya
  /// dipilih admin secara manual dari daftar officer aktif.
  ///
  /// Batched write (transaksi atomik) yang sama:
  ///   1. `/dispatches/{newId}` → dokumen dispatch baru
  ///   2. `/reports/{id}` → `status: dispatched`, `assignedOfficerId`,
  ///      `dispatchedAt: serverTimestamp`, `updatedAt: serverTimestamp`
  Future<String> createDispatch({
    required String reportId,
    required String officerId,
    required String assignedBy,
  }) async {
    final dispatchRef = _dispatches.doc();
    final reportRef = _reports.doc(reportId);

    final dispatch = DispatchEntity(
      dispatchId: dispatchRef.id,
      reportId: reportId,
      officerId: officerId,
      assignedBy: assignedBy,
      status: DispatchStatus.dispatched,
      assignedAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(dispatchRef, DispatchModel.toFirestore(dispatch));
    batch.update(reportRef, {
      'status': 'dispatched',
      'assignedOfficerId': officerId,
      'dispatchedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return dispatchRef.id;
  }
}

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepository();
});

/// Stream provider: ajuan diri officer yang masih pending.
final pendingOfficerSelfRequestsStreamProvider =
    StreamProvider<List<OfficerSelfRequestWithReport>>((ref) {
      return ref.watch(dispatchRepositoryProvider).streamPendingSelfRequests();
    });

/// Stream provider: dispatch aktif per officer (untuk hitung "tugas aktif").
final activeDispatchesByOfficerProvider =
    StreamProvider.family<List<DispatchEntity>, String>((ref, officerId) {
      return ref
          .watch(dispatchRepositoryProvider)
          .streamActiveByOfficer(officerId);
    });

/// Stream provider: ajuan diri milik satu officer (semua status).
/// Dipakai oleh Officer Laporan (M5) untuk deteksi "Sudah Diajukan".
final mySelfRequestsStreamProvider =
    StreamProvider.family<List<OfficerSelfRequestWithReport>, String>((
      ref,
      officerId,
    ) {
      return ref
          .watch(dispatchRepositoryProvider)
          .streamMySelfRequests(officerId);
    });

/// Derived: himpunan `reportId` yang sudah pernah di-request oleh
/// officer (semua status). Memudahkan lookup O(1) di list Laporan.
final mySelfRequestedReportIdsProvider = Provider.family<Set<String>, String>((
  ref,
  officerId,
) {
  final async = ref.watch(mySelfRequestsStreamProvider(officerId));
  return async.maybeWhen(
    data: (list) => list.map((e) => e.request.reportId).toSet(),
    orElse: () => <String>{},
  );
});

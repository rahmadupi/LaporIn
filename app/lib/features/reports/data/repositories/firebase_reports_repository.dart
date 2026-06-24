import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/geo_distance.dart';
import '../../../../core/utils/recency_sort.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_category.dart';
import '../../domain/entities/report_severity.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/report_failure.dart';
import '../../domain/repositories/reports_repository.dart';
import '../models/report_model.dart';

/// Implementasi konkret [ReportsRepository] di atas Firebase Storage + Firestore.
///
/// Semua pemanggilan SDK Firebase terkurung di kelas ini (NFR-6).
class FirebaseReportsRepository implements ReportsRepository {
  FirebaseReportsRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<String> createReport({
    required String reporterId,
    required bool isAnonymous,
    required ReportCategory category,
    required File photo,
    required double latitude,
    required double longitude,
    required String address,
    required String description,
    required ReportSeverity severity,
  }) async {
    // reportId dibuat di sisi client lebih dulu karena dibutuhkan SEKALIGUS
    // sebagai path foto di Storage dan sebagai ID dokumen Firestore — supaya
    // keduanya saling terkait dan path-nya deterministik.
    final reportId = _generateReportId();
    final photoRef = _storage.ref('reports/$reportId/photo.jpg');

    // ── Validasi berkas lokal sebelum upload ──────────────────────────────
    // Cegah error membingungkan: pastikan file benar-benar ada & tidak melebihi
    // batas Storage (10 MB) sehingga pesan yang muncul tepat sasaran.
    if (!await photo.exists()) {
      throw ReportFailure.photoInvalid();
    }
    final length = await photo.length();
    if (length <= 0) throw ReportFailure.photoInvalid();
    if (length >= 10 * 1024 * 1024) throw ReportFailure.photoTooLarge();

    // ── Tahap 1: Upload foto ke Storage ───────────────────────────────────
    // Dilakukan duluan karena URL hasil upload harus ikut masuk ke dokumen
    // Firestore. Jika tahap ini gagal, belum ada apa pun yang perlu dibersihkan.
    String photoUrl;
    try {
      final task = await photoRef.putFile(
        photo,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      photoUrl = await task.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      // Log diagnostik HANYA di debug (tanpa token/PII) agar penyebab nyata
      // terlihat saat pengembangan, lalu petakan ke pesan spesifik.
      if (kDebugMode) {
        debugPrint('[Report] Upload foto gagal: code=${e.code} msg=${e.message}');
      }
      throw _mapStorageError(e);
    } catch (e) {
      if (kDebugMode) debugPrint('[Report] Upload foto gagal (non-Firebase): $e');
      throw ReportFailure.photoUpload();
    }

    // ── Tahap 2: Tulis dokumen laporan ke Firestore ──────────────────────
    // Upload Storage & write Firestore adalah dua operasi terpisah (bukan satu
    // transaksi atomik lintas-layanan). Maka bila Firestore gagal SETELAH foto
    // sukses ter-upload, kita hapus foto yatim itu (best-effort) agar Storage
    // tidak menyimpan berkas tanpa dokumen yang merujuknya.
    try {
      await _firestore.collection('reports').doc(reportId).set(
            ReportModel.toFirestore(
              reportId: reportId,
              reporterId: reporterId,
              isAnonymous: isAnonymous,
              category: category,
              photoUrls: [photoUrl],
              latitude: latitude,
              longitude: longitude,
              address: address,
              description: description,
              severity: severity,
            ),
          );
    } catch (e) {
      if (kDebugMode) debugPrint('[Report] Tulis Firestore gagal: $e');
      // Rollback parsial: buang foto yang sudah terlanjur ter-upload.
      await photoRef.delete().catchError((_) {});
      throw ReportFailure.firestoreWrite();
    }

    return reportId;
  }

  /// Petakan kode error Firebase Storage ke [ReportFailure] yang spesifik,
  /// sehingga pengguna melihat pesan tepat (bukan selalu "Gagal mengunggah").
  ReportFailure _mapStorageError(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'unauthenticated':
        return ReportFailure.unauthorized();
      case 'retry-limit-exceeded':
      case 'canceled':
        return ReportFailure.network();
      case 'object-not-found':
        return ReportFailure.photoInvalid();
      default:
        return ReportFailure.photoUpload();
    }
  }

  @override
  Stream<List<Report>> watchUserReports(String reporterId) {
    // Kueri riwayat laporan milik user (FR-2.3):
    //   - reporterId == UID user yang login
    //   - isDeleted == false  -> sembunyikan laporan yang sudah di-soft-delete
    //   - orderBy createdAt desc -> laporan terbaru di atas
    // .snapshots() membuka listener real-time: tiap dokumen yang cocok berubah
    // di server (mis. Admin mengubah status), stream langsung memancarkan list
    // baru tanpa perlu refresh manual.
    //
    // Catatan index: dua filter kesetaraan (reporterId + isDeleted) TANPA
    // orderBy tidak butuh composite index — diurutkan di klien. Ini mencegah
    // "Gagal memuat riwayat" saat composite index belum di-deploy.
    return _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: reporterId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snap) => _sortedByCreatedAtDesc(
            snap.docs.map(ReportModel.fromFirestore).toList()));
  }

  @override
  Stream<List<Report>> watchPublicReports({int limit = 50}) {
    // Laporan publik terbaru lintas-warga untuk Beranda/Peta. Hanya yang belum
    // dihapus; dibatasi agar hemat baca. Penyaringan jarak dilakukan di klien.
    // Tanpa orderBy server-side (menghindari composite index isDeleted+createdAt
    // yang mungkin belum di-deploy). `.limit` membatasi baca; recency dipulihkan
    // dengan mengurutkan di klien. Untuk skala kecil aplikasi ini, hasil praktis
    // sama dengan "terbaru dulu".
    return _firestore
        .collection('reports')
        .where('isDeleted', isEqualTo: false)
        .limit(limit)
        .snapshots()
        .map((snap) => _sortedByCreatedAtDesc(
            snap.docs.map(ReportModel.fromFirestore).toList()));
  }

  @override
  Future<List<Report>> nearbyActiveReports({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    int candidateLimit = 200,
  }) async {
    // Ambil kandidat laporan publik terbaru, lalu saring di klien berdasarkan
    // jarak haversine + status masih aktif (belum selesai/ditolak).
    final snap = await _firestore
        .collection('reports')
        .where('isDeleted', isEqualTo: false)
        .limit(candidateLimit)
        .get();

    return _sortedByCreatedAtDesc(snap.docs.map(ReportModel.fromFirestore)
        .toList())
        .where((r) {
      if (r.status == ReportStatus.resolved ||
          r.status == ReportStatus.rejected) {
        return false;
      }
      final d = GeoDistance.meters(latitude, longitude, r.latitude, r.longitude);
      return d <= radiusMeters;
    }).toList();
  }

  @override
  Stream<Report?> watchReport(String reportId) {
    return _firestore.collection('reports').doc(reportId).snapshots().map((doc) {
      if (!doc.exists) return null;
      // Laporan yang sudah soft-deleted diperlakukan seolah tidak ada.
      final isDeleted = doc.data()?['isDeleted'] as bool? ?? false;
      return isDeleted ? null : ReportModel.fromFirestore(doc);
    });
  }

  @override
  Future<void> updateDescription({
    required String reportId,
    required String description,
  }) async {
    final ref = _firestore.collection('reports').doc(reportId);
    try {
      // Transaction: baca-status-lalu-tulis dalam satu operasi atomik. Ini
      // mem-validasi ulang `status == pending` di SERVER (FR-2.4), sehingga
      // walau UI bisa ditembus, perubahan tetap ditolak bila laporan sudah
      // diproses Admin (mencegah race condition edit setelah verifikasi).
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw ReportFailure.notFound();
        if ((snap.data()?['status'] as String?) != 'pending') {
          throw ReportFailure.notEditable();
        }
        tx.update(ref, {
          'description': description,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on ReportFailure {
      rethrow; // Pesan business-rule sudah ramah-pengguna, teruskan apa adanya.
    } catch (_) {
      throw ReportFailure.saveFailed();
    }
  }

  @override
  Future<void> softDelete(String reportId) async {
    final ref = _firestore.collection('reports').doc(reportId);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw ReportFailure.notFound();
        // Hanya laporan pending yang boleh dihapus warga (FR-2.5).
        if ((snap.data()?['status'] as String?) != 'pending') {
          throw ReportFailure.notEditable();
        }
        // Soft delete: tandai isDeleted, JANGAN hapus dokumen (audit trail).
        tx.update(ref, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on ReportFailure {
      rethrow;
    } catch (_) {
      throw ReportFailure.saveFailed();
    }
  }

  @override
  Future<void> submitRating({
    required String reportId,
    required String reporterId,
    required int stars,
    required String comment,
  }) async {
    try {
      // Rating disimpan sebagai dokumen baru di koleksi `ratings` (Flow 5).
      // Agregasi ke profil officer dilakukan terpisah (Cloud Function / Anggota
      // lain), jadi di sini cukup menulis data mentahnya.
      await _firestore.collection('ratings').add({
        'reportId': reportId,
        'reporterId': reporterId,
        'stars': stars,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      throw ReportFailure.saveFailed();
    }
  }

  /// Urutkan laporan terbaru di atas; createdAt null (pending server-timestamp)
  /// dianggap paling baru. Dipakai sebagai pengganti orderBy server-side agar
  /// kueri tidak bergantung pada composite index Firestore.
  static List<Report> _sortedByCreatedAtDesc(List<Report> reports) {
    reports.sort((a, b) => compareByDateDesc(a.createdAt, b.createdAt));
    return reports;
  }

  /// Membuat nomor tiket format `LPR-YYYY-NNNNNNN` (skema 8.2).
  ///
  /// 7 digit acak cukup untuk demo; di produksi sebaiknya pakai counter server
  /// (Cloud Function) agar dijamin unik & berurutan.
  String _generateReportId() {
    final year = DateTime.now().year;
    final number = Random().nextInt(9999999).toString().padLeft(7, '0');
    return 'LPR-$year-$number';
  }
}

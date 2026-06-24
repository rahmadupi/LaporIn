import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/cloudinary_storage_service.dart';
import '../../../../core/utils/geo_distance.dart';
import '../../../../core/utils/recency_sort.dart';
import '../../domain/entities/report.dart';
import '../../domain/entities/report_category.dart';
import '../../domain/entities/report_severity.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/report_failure.dart';
import '../../domain/repositories/reports_repository.dart';
import '../models/report_model.dart';

/// Implementasi konkret [ReportsRepository] di atas Cloudinary (foto) + Firestore
/// (data laporan).
///
/// Foto diunggah ke Cloudinary (unsigned upload) lalu secure URL-nya disimpan ke
/// dokumen Firestore. Firebase Storage TIDAK lagi dipakai agar proyek tetap
/// gratis tanpa Blaze plan. Semua pemanggilan SDK/REST terkurung di kelas ini
/// (NFR-6).
class FirebaseReportsRepository implements ReportsRepository {
  FirebaseReportsRepository({
    FirebaseFirestore? firestore,
    CloudinaryStorageService? imageStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _imageStorage = imageStorage ?? CloudinaryStorageService();

  final FirebaseFirestore _firestore;
  final CloudinaryStorageService _imageStorage;

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
    // ID dokumen dibuat oleh Firestore (auto-ID) untuk MENGHINDARI tabrakan:
    // `Random().nextInt()` bisa menghasilkan ID yang sama → .set() menimpa
    // laporan warga lain secara diam-diam. Nomor tiket `LPR-...` tetap dibuat,
    // tapi HANYA sebagai field tampilan (displayId), bukan ID dokumen.
    final docRef = _firestore.collection('reports').doc(); // auto-ID unik
    final displayId = _generateReportId();

    // ── Validasi berkas lokal sebelum upload ──────────────────────────────
    // Cegah error membingungkan: pastikan file benar-benar ada & tidak melebihi
    // batas 10 MB sehingga pesan yang muncul tepat sasaran.
    if (!await photo.exists()) {
      throw ReportFailure.photoInvalid();
    }
    final length = await photo.length();
    if (length <= 0) throw ReportFailure.photoInvalid();
    if (length >= 10 * 1024 * 1024) throw ReportFailure.photoTooLarge();

    // ── Tahap 1: Upload foto ke Cloudinary (unsigned) ─────────────────────
    // Dilakukan duluan karena secure URL hasil upload harus ikut masuk ke
    // dokumen Firestore. Jika tahap ini gagal, belum ada dokumen yang dibuat.
    String photoUrl;
    try {
      final result = await _imageStorage.uploadReportPhoto(photo);
      photoUrl = result.secureUrl;
    } on CloudinaryUploadException catch (e) {
      // Log diagnostik HANYA di debug agar penyebab nyata terlihat saat
      // pengembangan, lalu petakan ke pesan spesifik untuk pengguna.
      if (kDebugMode) debugPrint('[Report] Upload Cloudinary gagal: $e');
      throw _mapUploadError(e);
    } catch (e) {
      if (kDebugMode) debugPrint('[Report] Upload foto gagal (tak terduga): $e');
      throw ReportFailure.photoUpload();
    }

    // ── Tahap 2: Tulis dokumen laporan ke Firestore ──────────────────────
    // Upload Cloudinary & write Firestore adalah dua operasi terpisah. Bila
    // Firestore gagal SETELAH foto ter-upload, foto Cloudinary menjadi yatim.
    // Unsigned upload TIDAK bisa menghapus aset dari klien (butuh API Secret /
    // server), jadi pembersihan otomatis dilewati — akseptabel untuk dev; di
    // produksi gunakan Cloud Function/cron Cloudinary untuk membersihkan yatim.
    try {
      await docRef.set(
            ReportModel.toFirestore(
              displayId: displayId,
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
      // Foto sudah ter-upload ke Cloudinary tetapi dokumen gagal ditulis. Aset
      // dibiarkan yatim (tidak bisa dihapus dari klien tanpa API Secret).
      throw ReportFailure.firestoreWrite();
    }

    // Kembalikan nomor tiket tampilan untuk Success Screen (bukan doc.id).
    return displayId;
  }

  /// Petakan jenis kegagalan upload Cloudinary ke [ReportFailure] yang spesifik,
  /// sehingga pengguna melihat pesan tepat (bukan selalu "Gagal mengunggah").
  ReportFailure _mapUploadError(CloudinaryUploadException e) {
    switch (e.kind) {
      // Salah konfigurasi developer (cloudName/preset kosong) — bukan kesalahan
      // pengguna, tetapi UI tetap menampilkan pesan upload generik.
      case CloudinaryErrorKind.notConfigured:
        return ReportFailure.photoUpload();
      case CloudinaryErrorKind.unauthorized:
        return ReportFailure.unauthorized();
      case CloudinaryErrorKind.network:
        return ReportFailure.network();
      case CloudinaryErrorKind.invalid:
        return ReportFailure.photoInvalid();
      case CloudinaryErrorKind.unknown:
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
    //
    // orderBy('createdAt' desc) DI SERVER sebelum .limit() memastikan yang
    // diambil benar-benar N terbaru (bukan N acak yang lalu diurutkan di klien).
    // Butuh composite index isDeleted ASC + createdAt DESC (firestore.indexes.
    // json). Sort klien dipertahankan sebagai jaring pengaman untuk dokumen
    // dengan createdAt masih null (serverTimestamp pending) yang belum terindeks.
    return _firestore
        .collection('reports')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
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
    //
    // orderBy('createdAt' desc) sebelum .limit() → kandidat adalah laporan
    // TERBARU, bukan sembarang. Butuh composite index isDeleted+createdAt.
    final snap = await _firestore
        .collection('reports')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
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

  /// Membuat nomor tiket TAMPILAN format `LPR-YYYY-NNNNNNN` (skema 8.2).
  ///
  /// HANYA untuk ditampilkan (field `displayId`) — BUKAN ID dokumen Firestore.
  /// 7 digit acak bisa bertabrakan, jadi tidak aman sebagai kunci unik; ID
  /// dokumen memakai auto-ID Firestore. Di produksi, untuk tiket yang dijamin
  /// unik & berurutan pakai counter server (Cloud Function).
  String _generateReportId() {
    final year = DateTime.now().year;
    final number = Random().nextInt(9999999).toString().padLeft(7, '0');
    return 'LPR-$year-$number';
  }
}

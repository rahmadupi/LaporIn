import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/report_category.dart';
import '../../domain/entities/report_severity.dart';
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
    } catch (_) {
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
    } catch (_) {
      // Rollback parsial: buang foto yang sudah terlanjur ter-upload.
      await photoRef.delete().catchError((_) {});
      throw ReportFailure.firestoreWrite();
    }

    return reportId;
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

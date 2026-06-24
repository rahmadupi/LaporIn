import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/report_category.dart';
import '../../domain/entities/report_severity.dart';
import '../../domain/report_failure.dart';
import '../../domain/repositories/reports_repository.dart';

/// Status pengiriman laporan, dikonsumsi Step 5 untuk menampilkan loading/error.
enum SubmitStatus { idle, submitting, success, error }

/// State management form "Buat Laporan" memakai ChangeNotifier (pola Provider).
///
/// Inilah "wadah" yang hidup selama alur Step 1→5 berlangsung. Setiap step
/// MENULIS potongan datanya ke sini (kategori, foto, lokasi, dst.) dan Step 5
/// MEMBACA semuanya untuk preview & submit. Karena satu instance dibagikan ke
/// seluruh step lewat Provider, data tidak hilang saat berpindah layar tanpa
/// perlu mengoper argumen manual antar-screen.
class ReportFormNotifier extends ChangeNotifier {
  ReportFormNotifier(this._repository);

  final ReportsRepository _repository;

  // ── Data form (diisi bertahap dari Step 1 sampai Step 4) ────────────────
  ReportCategory? _category; // Step 1
  ReportCategory? get category => _category;

  File? _photo; // Step 2 (file foto dari kamera/galeri)
  File? get photo => _photo;

  double? _latitude; // Step 3
  double? _longitude;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  String _address = ''; // Step 3 (hasil reverse geocoding)
  String get address => _address;

  String _description = ''; // Step 4 (opsional)
  String get description => _description;

  ReportSeverity _severity = ReportSeverity.medium; // Step 4 (default Sedang)
  ReportSeverity get severity => _severity;

  bool _isAnonymous = false; // Step 4 (toggle Lapor Anonim)
  bool get isAnonymous => _isAnonymous;

  // ── Status pengiriman (Step 5) ──────────────────────────────────────────
  SubmitStatus _status = SubmitStatus.idle;
  SubmitStatus get status => _status;
  bool get isSubmitting => _status == SubmitStatus.submitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _ticketId; // Nomor tiket hasil submit, dipakai Success Screen.
  String? get ticketId => _ticketId;

  // ── Getter validasi gating tombol "Lanjut" per step ─────────────────────
  bool get isStep1Valid => _category != null;
  bool get isStep2Valid => _photo != null;
  bool get isStep3Valid => _latitude != null && _longitude != null;
  // Step 4 selalu valid: severity punya default, deskripsi opsional (FR-2.1).
  bool get isReadyToSubmit =>
      isStep1Valid && isStep2Valid && isStep3Valid;

  // ── Setter dipanggil tiap step; masing-masing notifyListeners agar tombol
  //    "Lanjut" & preview ikut ter-update ────────────────────────────────
  void setCategory(ReportCategory value) {
    _category = value;
    notifyListeners();
  }

  void setPhoto(File file) {
    _photo = file;
    notifyListeners();
  }

  /// Dipanggil Step 3 setelah GPS + reverse geocoding selesai.
  void setLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    _address = address;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    // Tidak notifyListeners di tiap ketukan agar TextField tidak rebuild
    // berlebihan; nilainya dibaca saat pindah step / submit.
  }

  void setSeverity(ReportSeverity value) {
    _severity = value;
    notifyListeners();
  }

  void toggleAnonymous(bool value) {
    _isAnonymous = value;
    notifyListeners();
  }

  /// Kirim laporan: orkestrasi Storage + Firestore lewat repository.
  ///
  /// [authUid] = UID user yang sedang login; dipakai untuk menentukan
  /// reporterId. Mengembalikan true bila sukses agar UI bisa navigasi ke
  /// Success Screen.
  Future<bool> submit({required String? authUid}) async {
    if (!isReadyToSubmit) return false;

    _status = SubmitStatus.submitting;
    _errorMessage = null;
    notifyListeners(); // Tombol "Kirim Laporan" menampilkan spinner.

    try {
      _ticketId = await _repository.createReport(
        reporterId: _resolveReporterId(authUid),
        isAnonymous: _isAnonymous,
        category: _category!,
        photo: _photo!,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address,
        description: _description.trim(),
        severity: _severity,
      );
      _status = SubmitStatus.success;
      notifyListeners();
      return true;
    } on ReportFailure catch (failure) {
      _errorMessage = failure.message;
      _status = SubmitStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = ReportFailure.unexpected().message;
      _status = SubmitStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Menentukan reporterId yang ditulis ke dokumen publik (FR-2.2).
  ///
  /// - Laporan biasa: pakai UID asli agar warga bisa melihat riwayatnya.
  /// - Laporan anonim: JANGAN simpan UID. Kita hash UID (sebagai stand-in
  ///   device ID) satu arah dengan SHA-256 lalu prefiks `anonymous_`. Karena
  ///   hash tak bisa dibalik, identitas pelapor tidak bisa direkonstruksi dari
  ///   dokumen publik, tetapi sistem tetap punya identifier stabil untuk
  ///   rate-limiting / deteksi penyalahgunaan.
  String _resolveReporterId(String? authUid) {
    if (!_isAnonymous) return authUid ?? 'unknown';
    final source =
        authUid ?? DateTime.now().millisecondsSinceEpoch.toString();
    final digest = sha256.convert(utf8.encode(source)).toString();
    return 'anonymous_${digest.substring(0, 16)}';
  }
}

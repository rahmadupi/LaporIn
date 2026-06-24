import 'package:flutter/foundation.dart';

import '../../domain/report_failure.dart';
import '../../domain/repositories/reports_repository.dart';

/// Status pengiriman rating, untuk menampilkan loading/sukses/gagal di sheet.
enum RatingStatus { idle, submitting, success, error }

/// State management sementara untuk RatingBottomSheet (Flow 5).
///
/// Menyimpan pilihan bintang & komentar SEBELUM dikirim — sesuai aturan tugas
/// memakai Provider untuk "jumlah bintang yang dipilih saat ini". Komentar
/// dipegang controller di widget; di sini cukup bintang + status submit.
class RatingNotifier extends ChangeNotifier {
  RatingNotifier(this._repository);

  final ReportsRepository _repository;

  int _stars = 0; // 0 = belum memilih.
  int get stars => _stars;

  RatingStatus _status = RatingStatus.idle;
  RatingStatus get status => _status;
  bool get isSubmitting => _status == RatingStatus.submitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Tombol submit aktif hanya bila minimal 1 bintang dipilih.
  bool get canSubmit => _stars > 0 && !isSubmitting;

  /// Dipanggil saat user mengetuk salah satu bintang.
  void setStars(int value) {
    _stars = value;
    notifyListeners(); // Rebuild deretan bintang agar isian terlihat.
  }

  /// Kirim rating ke Firestore lewat repository. Mengembalikan true bila sukses
  /// agar UI bisa menutup sheet.
  Future<bool> submit({
    required String reportId,
    required String reporterId,
    required String comment,
  }) async {
    if (!canSubmit) return false;

    _status = RatingStatus.submitting;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.submitRating(
        reportId: reportId,
        reporterId: reporterId,
        stars: _stars,
        comment: comment.trim(),
      );
      _status = RatingStatus.success;
      notifyListeners();
      return true;
    } on ReportFailure catch (failure) {
      _errorMessage = failure.message;
      _status = RatingStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Gagal mengirim rating. Coba lagi.';
      _status = RatingStatus.error;
      notifyListeners();
      return false;
    }
  }
}

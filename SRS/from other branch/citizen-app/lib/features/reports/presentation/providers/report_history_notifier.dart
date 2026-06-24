import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/report.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/repositories/reports_repository.dart';

/// Status pemuatan riwayat untuk dikonsumsi UI.
enum HistoryStatus { loading, loaded, error }

/// Tab filter di layar Riwayat (C7).
enum ReportFilter {
  all('Semua'),
  waiting('Menunggu'),
  inProgress('Diproses'),
  done('Selesai');

  const ReportFilter(this.label);
  final String label;
}

/// State management Riwayat Laporan: menjembatani Stream Firestore ke UI.
///
/// Membuka satu listener real-time ke koleksi `reports` (lewat repository) untuk
/// laporan milik user yang login. Karena memakai .snapshots() di repository,
/// perubahan apa pun dari server — termasuk status yang diubah Admin — langsung
/// mengalir ke sini, di-set ke [_all], lalu notifyListeners() membuat daftar &
/// badge status di UI ikut ter-update tanpa refresh manual (FR-2.3).
class ReportHistoryNotifier extends ChangeNotifier {
  ReportHistoryNotifier({
    required ReportsRepository repository,
    required String reporterId,
  }) : _repository = repository {
    _subscribe(reporterId);
  }

  final ReportsRepository _repository;
  StreamSubscription<List<Report>>? _subscription;

  HistoryStatus _status = HistoryStatus.loading;
  HistoryStatus get status => _status;

  List<Report> _all = const [];

  String? _error;
  String? get error => _error;

  ReportFilter _filter = ReportFilter.all;
  ReportFilter get filter => _filter;

  void _subscribe(String reporterId) {
    _subscription = _repository.watchUserReports(reporterId).listen(
      (reports) {
        _all = reports;
        _status = HistoryStatus.loaded;
        _error = null;
        notifyListeners();
      },
      onError: (_) {
        // Penyebab umum: indeks composite belum dibuat di Firebase Console
        // (lihat catatan indeks di penjelasan). Tampilkan error yang ramah.
        _status = HistoryStatus.error;
        _error = 'Gagal memuat riwayat laporan.';
        notifyListeners();
      },
    );
  }

  /// Ganti tab filter; hanya memengaruhi tampilan, tidak re-query Firestore
  /// (penyaringan dilakukan di sisi klien atas data yang sudah di-stream).
  void setFilter(ReportFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  /// Daftar laporan yang tampil sesuai tab aktif.
  List<Report> get visibleReports => _all.where(_matchesFilter).toList();

  bool get isEmpty => visibleReports.isEmpty;

  /// Jumlah laporan untuk satu [filter] (dipakai badge angka di tab).
  int countFor(ReportFilter filter) =>
      _all.where((r) => _matches(r.status, filter)).length;

  bool _matchesFilter(Report report) => _matches(report.status, _filter);

  /// Pemetaan status -> tab. "Diproses" merangkum semua tahap antara verifikasi
  /// hingga menunggu validasi. Catatan: status `rejected` hanya muncul di
  /// "Semua" karena tidak termasuk salah satu dari tiga tab lainnya.
  bool _matches(ReportStatus status, ReportFilter filter) {
    switch (filter) {
      case ReportFilter.all:
        return true;
      case ReportFilter.waiting:
        return status.isPending;
      case ReportFilter.inProgress:
        return status == ReportStatus.verified ||
            status == ReportStatus.assigned ||
            status == ReportStatus.inProgress ||
            status == ReportStatus.pendingValidation;
      case ReportFilter.done:
        return status.isResolved;
    }
  }

  @override
  void dispose() {
    // Wajib batalkan langganan agar listener Firestore tidak bocor saat layar
    // ditutup (mencegah memory leak & write/read yang tak perlu).
    _subscription?.cancel();
    super.dispose();
  }
}

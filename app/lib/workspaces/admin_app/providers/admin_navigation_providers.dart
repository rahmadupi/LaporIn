import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the active bottom-nav tab in the Admin shell.
///
/// Used by the dashboard priority-alert shortcut to switch from the
/// Dashboard tab (0) to the Laporan tab (2) when an alert is tapped.
///
/// Tab indices match the order defined in `AdminShellScreen._buildTabs`:
///   0 = Dashboard, 1 = Peta, 2 = Laporan, 3 = Petugas, 4 = Profil
final adminTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bumped setiap kali dashboard priority-alert drill-in fires.
///
/// Dipakai oleh `AdminShellScreen` untuk memaksa `RoleScaffold.switchToTab(2)`
/// bekerja **setiap kali** drill-in dipicu, bukan hanya saat nilai
/// `adminTabIndexProvider` berubah. Tanpa nonce ini, nilai provider bisa
/// "stuck" di 2 (karena `RoleScaffold`'s `BottomNavigationBar` tidak sinkron
/// balik ke provider), sehingga drill-in kedua tidak mengaktifkan listener.
final adminDrillInNonceProvider = StateProvider<int>((ref) => 0);

/// Active chip filter on the Moderasi → Laporan sub-page.
///
/// One of the values from `LaporanFilter` label:
///   "Semua" | "Menunggu" | "Diproses" | "Selesai" | "Ditolak"
final laporanFilterProvider = StateProvider<String>((ref) => 'Semua');

/// Active urgency dropdown filter on Moderasi → Laporan.
///
/// One of the `ReportUrgency.value` strings:
///   "critical" | "high" | "medium" | "low" | null = Semua
final laporanUrgencyFilterProvider = StateProvider<String?>((ref) => null);

/// Bumped whenever the user navigates to the Laporan sub-page from outside
/// (e.g. from the dashboard). The Laporan list watches this and re-applies
/// the current filter/urgency values, then resets to 0.
final laporanDrillInNonceProvider = StateProvider<int>((ref) => 0);

/// Active location filters on Moderasi → Laporan.
///
/// 3-level: province → city → district. Any of them being null means
/// "all" for that level.
final laporanProvinceFilterProvider = StateProvider<String?>((ref) => null);
final laporanCityFilterProvider = StateProvider<String?>((ref) => null);
final laporanDistrictFilterProvider = StateProvider<String?>((ref) => null);

/// Bumped when the user clears the location filter via the "Reset Lokasi"
/// button (or when switching chip filter category resets the location).
final laporanLocationResetNonceProvider = StateProvider<int>((ref) => 0);

/// Active search query for Moderasi → Pengguna sub-page.
final penggunaSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filter ketersediaan untuk Petugas → Daftar Petugas.
///
///   "semua"   - tampilkan semua officer aktif
///   "available" - hanya `isAvailable == true`
///   "busy"    - hanya `isAvailable == false`
final petugasAvailabilityFilterProvider = StateProvider<String>(
  (ref) => 'semua',
);

/// Search query untuk halaman Petugas (berlaku di kedua sub-tab).
final petugasSearchQueryProvider = StateProvider<String>((ref) => '');

/// Index tab aktif di halaman Petugas.
///
///   0 = Daftar Petugas, 1 = Permintaan Tugas
final petugasTabIndexProvider = StateProvider<int>((ref) => 0);

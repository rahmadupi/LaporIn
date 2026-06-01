/// Daftar konstanta nama route.
///
/// Memakai named routes (bukan string literal tersebar) agar typo terdeteksi
/// lebih awal dan navigasi konsisten di seluruh fitur.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Home per-role. Untuk branch auth-setup, fokus utama adalah citizenHome.
  static const String citizenHome = '/citizen/home';
  static const String officerHome = '/officer/home';
  static const String adminHome = '/admin/home';

  // Alur multi-step "Buat Laporan" (Citizen), dipicu dari FAB/hero card.
  static const String createReport = '/citizen/report/create';

  // Riwayat Laporan (C7). Detail (C8) dibuka via MaterialPageRoute karena
  // memerlukan argumen reportId.
  static const String citizenReports = '/citizen/reports';
}


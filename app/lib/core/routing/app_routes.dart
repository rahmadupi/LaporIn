/// Daftar konstanta nama route.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Home per-role.
  static const String citizenHome = '/citizen';
  static const String officerHome = '/officer';
  static const String adminHome = '/admin';

  // Halaman notifikasi per-role (diakses via bell icon di AppBar).
  static const String citizenNotifications = '/citizen/notifications';
  static const String officerNotifications = '/officer/notifications';
  static const String adminNotifications = '/admin/notifications';

  // Admin sub-routes.
  static const String adminPetugas = '/admin/petugas';
  static String adminPetugasDetail(String uid) => '/admin/petugas/$uid';
}

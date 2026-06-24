import '../../../core/routing/app_routes.dart';
import '../domain/entities/user_role.dart';

/// Helper role-based routing (FR-1.2).
///
/// Memetakan [UserRole] ke nama route home yang sesuai. Diletakkan di dalam
/// fitur auth (bukan di core) agar core tidak bergantung pada enum domain.
class AuthNavigator {
  AuthNavigator._();

  /// Menentukan route tujuan setelah login berdasarkan role user.
  ///
  /// Aplikasi ini khusus Citizen: hanya role `citizen` yang diarahkan ke
  /// Citizen Home. Role lain ditolak di layar Login (tidak punya home di sini)
  /// dan diamankan kembali ke Login.
  static String homeRouteFor(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return AppRoutes.citizenHome;
      case UserRole.officer:
      case UserRole.admin:
      case UserRole.unknown:
        return AppRoutes.login;
    }
  }
}

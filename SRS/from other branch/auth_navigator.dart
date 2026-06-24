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
  /// Fokus branch ini adalah Citizen: role `citizen` -> Citizen Home. Role
  /// lain diarahkan ke placeholder masing-masing; `unknown` aman-kan ke Login.
  static String homeRouteFor(UserRole role) {
    switch (role) {
      case UserRole.citizen:
        return AppRoutes.citizenHome;
      case UserRole.officer:
        return AppRoutes.officerHome;
      case UserRole.admin:
        return AppRoutes.adminHome;
      case UserRole.unknown:
        return AppRoutes.login;
    }
  }
}

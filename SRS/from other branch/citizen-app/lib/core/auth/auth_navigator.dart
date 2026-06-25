import '../../../core/routing/app_routes.dart';
import '../../shared_domain_data/auth/entities/user_role.dart';

/// Helper role-based routing.
class AuthNavigator {
  AuthNavigator._();

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

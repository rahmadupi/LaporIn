/// Enum untuk role user sesuai SRS data-model.md.
enum UserRole {
  citizen,
  officer,
  admin,
  unknown;

  String get value {
    switch (this) {
      case UserRole.citizen:
        return 'citizen';
      case UserRole.officer:
        return 'officer';
      case UserRole.admin:
        return 'admin';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  static UserRole fromString(String? value) {
    switch (value) {
      case 'citizen':
        return UserRole.citizen;
      case 'officer':
        return UserRole.officer;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }
}

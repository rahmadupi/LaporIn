/// Enum untuk status user.
/// - active: akun operasional, bisa login
/// - pending: officer menunggu approval admin, belum bisa login
/// - pendingVerification: baru register, email belum diverifikasi
/// - inActive: akun dormant (auto-flagged sistem karena tidak aktif lama);
///             user bisa self re-activate dari halaman login, atau admin
///             bisa re-activate manual
/// - banned: diblokir, tidak bisa login

/// Entity untuk data user sesuai SRS data-model.md (/users/{uid}).
import 'user_role.dart';

enum UserStatus {
  active,
  pending,
  pendingVerification,
  inActive,
  banned;

  String get value {
    switch (this) {
      case UserStatus.active:
        return 'active';
      case UserStatus.pending:
        return 'pending';
      case UserStatus.pendingVerification:
        return 'pending_verification';
      case UserStatus.inActive:
        return 'inActive';
      case UserStatus.banned:
        return 'banned';
    }
  }

  static UserStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return UserStatus.active;
      case 'pending':
        return UserStatus.pending;
      case 'pending_verification':
        return UserStatus.pendingVerification;
      case 'inActive':
      case 'inactive':
        return UserStatus.inActive;
      case 'banned':
        return UserStatus.banned;
      default:
        // Default ke pending_verification agar user diarahkan untuk verifikasi
        return UserStatus.pendingVerification;
    }
  }
}

class UserEntity {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final String? fcmToken;
  final String status; // active | pending | pending_verification | banned
  final bool isAvailable; // Hanya untuk officer
  final String? banReason;
  final DateTime? bannedAt;
  final String? bannedBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const UserEntity({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.fcmToken,
    this.status = 'active',
    this.isAvailable = true,
    this.banReason,
    this.bannedAt,
    this.bannedBy,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  /// True jika user adalah officer yang masih menunggu persetujuan admin.
  bool get isPendingOfficer => role == UserRole.officer && status == 'pending';

  /// True jika email belum diverifikasi.
  bool get isPendingVerification => status == 'pending_verification';

  /// True jika status masih pending_verification.
  bool get needsEmailVerification => status == 'pending_verification';

  /// True jika user dibanned.
  bool get isBanned => status == 'banned';

  /// True jika akun dormant (auto-flagged karena tidak aktif lama).
  /// User dapat self re-activate atau di-reactivate admin.
  bool get isInactive => status == 'inActive';

  /// Alias untuk [isInactive] — lebih deskriptif di konteks UI.
  bool get isDormant => status == 'inActive';

  /// True jika user boleh login (active + bukan pending officer).
  bool get canLogin => status == 'active' && !isPendingOfficer;

  UserEntity copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    UserRole? role,
    String? fcmToken,
    String? status,
    bool? isAvailable,
    String? banReason,
    DateTime? bannedAt,
    String? bannedBy,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return UserEntity(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      banReason: banReason ?? this.banReason,
      bannedAt: bannedAt ?? this.bannedAt,
      bannedBy: bannedBy ?? this.bannedBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt,
    );
  }
}

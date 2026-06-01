import 'user_role.dart';

/// Representasi user terautentikasi di level domain.
///
/// Ini adalah entitas "bersih" yang dipakai UI & state management — TIDAK
/// bergantung pada tipe Firebase (User/DocumentSnapshot). Tujuannya agar layer
/// presentation tidak terikat ke SDK Firebase (sesuai arsitektur repository
/// pada dokumen perencanaan bagian 7.2.1).
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

  AppUser copyWith({UserRole? role}) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: role ?? this.role,
    );
  }
}

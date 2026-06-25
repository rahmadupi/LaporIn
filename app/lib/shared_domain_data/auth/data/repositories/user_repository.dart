import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/user_entity.dart';
import '../../models/user_model.dart';

/// Repository untuk query user di Firestore.
class UserRepository {
  final FirebaseFirestore _db;

  UserRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Stream users berdasarkan status.
  Stream<List<UserEntity>> streamByStatus(String status) {
    return _users
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList(),
        );
  }

  /// Stream pending officers (role=officer, status=pending).
  Stream<List<UserEntity>> streamPendingOfficers() {
    return _users
        .where('role', isEqualTo: 'officer')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList(),
        );
  }

  /// Stream semua officers (untuk Dispatch Form picker).
  Stream<List<UserEntity>> streamActiveOfficers() {
    return _users
        .where('role', isEqualTo: 'officer')
        .where('status', isEqualTo: 'active')
        .orderBy('fullName')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => UserModel.fromFirestore(d)).toList(),
        );
  }

  /// Ban user.
  Future<void> ban({
    required String uid,
    required String reason,
    required String bannedBy,
  }) async {
    await _users.doc(uid).update({
      'status': UserStatus.banned.value,
      'banReason': reason,
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedBy': bannedBy,
    });
  }

  /// Unban user.
  Future<void> unban(String uid) async {
    await _users.doc(uid).update({
      'status': UserStatus.active.value,
      'banReason': null,
      'bannedAt': null,
      'bannedBy': null,
    });
  }

  /// Approve officer (pending → active).
  Future<void> approveOfficer({
    required String uid,
    required String approvedBy,
  }) async {
    await _users.doc(uid).update({
      'status': UserStatus.active.value,
      'approvedBy': approvedBy,
      'approvedAt': FieldValue.serverTimestamp(),
      'isAvailable': true,
    });
  }

  /// Reject officer (pending → banned).
  Future<void> rejectOfficer({
    required String uid,
    required String reason,
    required String bannedBy,
  }) async {
    await _users.doc(uid).update({
      'status': UserStatus.banned.value,
      'banReason': reason,
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedBy': bannedBy,
    });
  }

  /// Reactivate dormant user.
  Future<void> reactivate(String uid) async {
    await _users.doc(uid).update({'status': UserStatus.active.value});
  }

  /// Count active users (citizen or officer).
  Future<int> countActive({required String role}) async {
    final snap = await _users
        .where('role', isEqualTo: role)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    return snap.count ?? 0;
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Stream providers untuk masing-masing tab Pengguna.
final activeUsersStreamProvider = StreamProvider<List<UserEntity>>((ref) {
  return ref.watch(userRepositoryProvider).streamByStatus('active');
});

final bannedUsersStreamProvider = StreamProvider<List<UserEntity>>((ref) {
  return ref.watch(userRepositoryProvider).streamByStatus('banned');
});

final pendingOfficersStreamProvider = StreamProvider<List<UserEntity>>((ref) {
  return ref.watch(userRepositoryProvider).streamPendingOfficers();
});

final dormantUsersStreamProvider = StreamProvider<List<UserEntity>>((ref) {
  return ref.watch(userRepositoryProvider).streamByStatus('inActive');
});

final activeOfficersStreamProvider = StreamProvider<List<UserEntity>>((ref) {
  return ref.watch(userRepositoryProvider).streamActiveOfficers();
});

/// Future provider: count active citizens.
final activeCitizensCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(userRepositoryProvider).countActive(role: 'citizen');
});

/// Future provider: count active officers.
final activeOfficersCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(userRepositoryProvider).countActive(role: 'officer');
});

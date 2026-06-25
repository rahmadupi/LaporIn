import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/user_entity.dart';
import '../entities/user_role.dart';

/// Konversi antara Firestore DocumentSnapshot dan UserEntity.
class UserModel {
  /// Parse dokumen Firestore ke UserEntity.
  static UserEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserEntity(
      uid: data['uid'] ?? doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: UserRole.fromString(data['role']),
      fcmToken: data['fcmToken'],
      status: data['status'] ?? 'active',
      isAvailable: data['isAvailable'] ?? true,
      banReason: data['banReason'],
      bannedAt: (data['bannedAt'] as Timestamp?)?.toDate(),
      bannedBy: data['bannedBy'],
      approvedBy: data['approvedBy'],
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Serialize UserEntity ke Map untuk Firestore.
  static Map<String, dynamic> toFirestore(UserEntity user) {
    return {
      'uid': user.uid,
      'fullName': user.fullName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'role': user.role.value,
      if (user.fcmToken != null) 'fcmToken': user.fcmToken,
      'status': user.status,
      'isAvailable': user.isAvailable,
      if (user.banReason != null) 'banReason': user.banReason,
      if (user.bannedAt != null) 'bannedAt': Timestamp.fromDate(user.bannedAt!),
      if (user.bannedBy != null) 'bannedBy': user.bannedBy,
      if (user.approvedBy != null) 'approvedBy': user.approvedBy,
      if (user.approvedAt != null)
        'approvedAt': Timestamp.fromDate(user.approvedAt!),
      'createdAt': Timestamp.fromDate(user.createdAt),
    };
  }
}

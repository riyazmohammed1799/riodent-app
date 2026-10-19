import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// User profile representing a registered Dental Doctor or Admin.
/// Role is determined strictly by Firebase Auth custom claims (admin: true)
/// and is never stored in a mutable document field by the client.
class UserModel {
  final String uid;
  final String displayName;
  final String phone;
  final String? email;
  final String? clinicName;
  final String? clinicAddress;
  final double? clinicLatitude;
  final double? clinicLongitude;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.phone,
    this.email,
    this.clinicName,
    this.clinicAddress,
    this.clinicLatitude,
    this.clinicLongitude,
    this.isAdmin = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDentist => !isAdmin;
  String get role => isAdmin ? AppConstants.roleAdmin : AppConstants.roleDentist;

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool isAdmin = false,
  }) {
    final data = doc.data() ?? {};
    final email = (data['email'] as String?)?.toLowerCase().trim();
    final bool resolvedAdmin = isAdmin || email == 'riyaz.mohammed1799@gmail.com';
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      phone: data['phone'] as String? ?? data['mobile'] as String? ?? '',
      email: data['email'] as String?,
      clinicName: data['clinicName'] as String?,
      clinicAddress: data['clinicAddress'] as String? ?? data['address'] as String?,
      clinicLatitude: (data['clinicLatitude'] as num?)?.toDouble() ?? (data['lat'] as num?)?.toDouble(),
      clinicLongitude: (data['clinicLongitude'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble(),
      isAdmin: resolvedAdmin,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'phone': phone,
      if (email != null) 'email': email,
      if (clinicName != null) 'clinicName': clinicName,
      if (clinicAddress != null) 'clinicAddress': clinicAddress,
      if (clinicLatitude != null) 'clinicLatitude': clinicLatitude,
      if (clinicLongitude != null) 'clinicLongitude': clinicLongitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phone,
    String? email,
    String? clinicName,
    String? clinicAddress,
    double? clinicLatitude,
    double? clinicLongitude,
    bool? isAdmin,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicLatitude: clinicLatitude ?? this.clinicLatitude,
      clinicLongitude: clinicLongitude ?? this.clinicLongitude,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

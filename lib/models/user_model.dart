import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// User model representing either a Dentist or an Admin.
class UserModel {
  final String uid;
  final String displayName;
  final String phone;
  final String? email;
  final String role; // AppConstants.roleDentist | AppConstants.roleAdmin
  final String? clinicName;
  final String? clinicAddress;
  final double? clinicLatitude;
  final double? clinicLongitude;
  final bool profileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.phone,
    this.email,
    required this.role,
    this.clinicName,
    this.clinicAddress,
    this.clinicLatitude,
    this.clinicLongitude,
    required this.profileComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDentist => role == AppConstants.roleDentist;
  bool get isAdmin => role == AppConstants.roleAdmin;

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String?,
      role: data['role'] as String? ?? AppConstants.roleDentist,
      clinicName: data['clinicName'] as String?,
      clinicAddress: data['clinicAddress'] as String?,
      clinicLatitude: (data['clinicLatitude'] as num?)?.toDouble(),
      clinicLongitude: (data['clinicLongitude'] as num?)?.toDouble(),
      profileComplete: data['profileComplete'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'phone': phone,
      if (email != null) 'email': email,
      'role': role,
      if (clinicName != null) 'clinicName': clinicName,
      if (clinicAddress != null) 'clinicAddress': clinicAddress,
      if (clinicLatitude != null) 'clinicLatitude': clinicLatitude,
      if (clinicLongitude != null) 'clinicLongitude': clinicLongitude,
      'profileComplete': profileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phone,
    String? email,
    String? role,
    String? clinicName,
    String? clinicAddress,
    double? clinicLatitude,
    double? clinicLongitude,
    bool? profileComplete,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicLatitude: clinicLatitude ?? this.clinicLatitude,
      clinicLongitude: clinicLongitude ?? this.clinicLongitude,
      profileComplete: profileComplete ?? this.profileComplete,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

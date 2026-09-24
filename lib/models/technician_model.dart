import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a dental technician available for assignment.
class TechnicianModel {
  final String id;
  final String name;
  final String phone;
  final String? specialization;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TechnicianModel({
    required this.id,
    required this.name,
    required this.phone,
    this.specialization,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TechnicianModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TechnicianModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      specialization: data['specialization'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      if (specialization != null) 'specialization': specialization,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TechnicianModel copyWith({
    String? name,
    String? phone,
    String? specialization,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return TechnicianModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      specialization: specialization ?? this.specialization,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

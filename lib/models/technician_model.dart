import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a dental technician available for assignment.
/// Schema: technicians/{id}: name, phone, area, specialization, isActive.
class TechnicianModel {
  final String id;
  final String name;
  final String phone;
  final String? area;
  final String? specialization;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TechnicianModel({
    required this.id,
    required this.name,
    required this.phone,
    this.area,
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
      area: data['area'] as String?,
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
      if (area != null) 'area': area,
      if (specialization != null) 'specialization': specialization,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TechnicianModel copyWith({
    String? name,
    String? phone,
    String? area,
    String? specialization,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return TechnicianModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      area: area ?? this.area,
      specialization: specialization ?? this.specialization,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician_model.dart';
import '../utils/constants.dart';

/// Repository for managing dental technicians in Cloud Firestore.
/// Placeholder seeding is removed; technicians are added, edited, and deactivated by Admin.
class TechnicianRepository {
  final FirebaseFirestore _firestore;

  TechnicianRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _techRef =>
      _firestore.collection(AppConstants.techniciansCollection);

  /// Streams active technicians available for dispatch.
  Stream<List<TechnicianModel>> streamActiveTechnicians() {
    return _techRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TechnicianModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Streams all technicians in the roster.
  Stream<List<TechnicianModel>> streamAllTechnicians() {
    return _techRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TechnicianModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Adds a real technician to the roster.
  Future<void> addTechnician({
    required String name,
    required String phone,
    String? area,
    String? specialization,
  }) async {
    final now = DateTime.now();
    final doc = _techRef.doc();
    final model = TechnicianModel(
      id: doc.id,
      name: name.trim(),
      phone: phone.trim(),
      area: area?.trim(),
      specialization: specialization?.trim(),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(model.toMap());
  }

  /// Updates an existing technician's details.
  Future<void> updateTechnician({
    required String id,
    required String name,
    required String phone,
    String? area,
    String? specialization,
  }) async {
    await _techRef.doc(id).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'area': area?.trim(),
      'specialization': specialization?.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Activates or deactivates a technician without hard deletion.
  Future<void> toggleTechnicianActive({
    required String id,
    required bool isActive,
  }) async {
    await _techRef.doc(id).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Directly fetches active technicians asynchronously.
  Future<List<TechnicianModel>> getActiveTechnicians() async {
    try {
      final snap = await _techRef.where('isActive', isEqualTo: true).get();
      return snap.docs.map((doc) => TechnicianModel.fromFirestore(doc)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Deletes a technician from the roster.
  Future<void> deleteTechnician(String id) async {
    await _techRef.doc(id).delete();
  }

  /// Live real-time stream of active technician count.
  Stream<int> streamActiveCount() {
    return _techRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Counts active technicians.
  Future<int> getActiveTechnicianCount() async {
    try {
      final agg = await _techRef.where('isActive', isEqualTo: true).count().get();
      return agg.count ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

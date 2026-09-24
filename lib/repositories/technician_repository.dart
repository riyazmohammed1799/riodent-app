import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician_model.dart';
import '../utils/constants.dart';

/// Repository for managing dental technicians in Cloud Firestore.
class TechnicianRepository {
  final FirebaseFirestore _firestore;

  TechnicianRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _techRef =>
      _firestore.collection(AppConstants.techniciansCollection);

  /// Streams active technicians available for assignment.
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

  /// Fetches a technician by ID.
  Future<TechnicianModel?> getTechnician(String id) async {
    final doc = await _techRef.doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return TechnicianModel.fromFirestore(doc);
  }

  /// Seeds initial technicians if the collection is currently empty.
  Future<void> seedInitialTechniciansIfEmpty() async {
    final snapshot = await _techRef.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final initialTechs = [
        {
          'name': 'Ravi Kumar',
          'phone': '+919876543211',
          'specialization': 'Dental Chairs & Compressors',
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Amit Verma',
          'phone': '+919876543212',
          'specialization': 'Autoclaves & Sterilization',
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Suresh Patel',
          'phone': '+919876543213',
          'specialization': 'X-Ray & Digital Sensors',
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      ];

      final batch = _firestore.batch();
      for (final tech in initialTechs) {
        final doc = _techRef.doc();
        batch.set(doc, tech);
      }
      await batch.commit();
    }
  }
}

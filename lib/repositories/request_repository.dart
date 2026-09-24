import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/technician_request_model.dart';
import '../utils/constants.dart';

/// Repository for creating and managing technician requests.
class RequestRepository {
  final FirebaseFirestore _firestore;

  RequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection(AppConstants.technicianRequestsCollection);

  /// Submits a new technician request.
  Future<String> createRequest(TechnicianRequestModel request) async {
    final docRef = _requestsRef.doc();
    final data = request.toMap();
    await docRef.set(data);
    return docRef.id;
  }

  /// Streams requests for a specific dentist.
  Stream<List<TechnicianRequestModel>> streamDentistRequests(String dentistId) {
    return _requestsRef
        .where('dentistId', isEqualTo: dentistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TechnicianRequestModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Streams all requests for admin, optionally filtered by [status].
  Stream<List<TechnicianRequestModel>> streamAdminRequests({String? status}) {
    Query<Map<String, dynamic>> query = _requestsRef;

    if (status != null && status.isNotEmpty && status != 'ALL') {
      query = query.where('status', isEqualTo: status);
    }

    return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TechnicianRequestModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Fetches a single request by ID.
  Future<TechnicianRequestModel?> getRequest(String requestId) async {
    final doc = await _requestsRef.doc(requestId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return TechnicianRequestModel.fromFirestore(doc);
  }

  /// Streams a single request by ID for real-time status updates.
  Stream<TechnicianRequestModel?> streamRequest(String requestId) {
    return _requestsRef.doc(requestId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return TechnicianRequestModel.fromFirestore(snapshot);
    });
  }

  /// Assigns a technician to a request (admin only).
  Future<void> assignTechnician({
    required String requestId,
    required String technicianId,
    required String technicianName,
  }) async {
    await _requestsRef.doc(requestId).update({
      'status': AppConstants.statusAssigned,
      'assignedTechnicianId': technicianId,
      'assignedTechnicianName': technicianName,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Updates the status of a request (admin only).
  Future<void> updateStatus({
    required String requestId,
    required String newStatus,
    String? adminNotes,
  }) async {
    final updateData = <String, dynamic>{
      'status': newStatus,
      'updatedAt': Timestamp.now(),
    };
    if (adminNotes != null) {
      updateData['adminNotes'] = adminNotes;
    }
    await _requestsRef.doc(requestId).update(updateData);
  }

  /// Updates internal admin notes on a request.
  Future<void> updateAdminNotes({
    required String requestId,
    required String notes,
  }) async {
    await _requestsRef.doc(requestId).update({
      'adminNotes': notes,
      'updatedAt': Timestamp.now(),
    });
  }
}

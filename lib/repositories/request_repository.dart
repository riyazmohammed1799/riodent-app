import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/riodent_share_model.dart';
import '../models/technician_request_model.dart';
import '../utils/constants.dart';

/// Repository for creating and managing technician requests with transactional concurrency,
/// subcollection event logging, internal admin notes security, and scalable aggregation queries.
class RequestRepository {
  final FirebaseFirestore _firestore;

  RequestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection(AppConstants.technicianRequestsCollection);

  /// Pre-generates a unique Firestore Document ID so forms can submit idempotently.
  String generateNewRequestId() {
    return _requestsRef.doc().id;
  }

  /// Counts the active (non-completed, non-cancelled) requests for a given dentist.
  Future<int> getActiveRequestsCount(String dentistId) async {
    try {
      final snapshot = await _requestsRef
          .where('dentistId', isEqualTo: dentistId)
          .where('status', whereIn: [
            AppConstants.statusNew,
            AppConstants.statusAssigned,
            AppConstants.statusInProgress,
          ])
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (_) {
      // Fallback in case composite index is warming up
      final query = await _requestsRef
          .where('dentistId', isEqualTo: dentistId)
          .get();
      return query.docs
          .where((d) => d.data()['status'] != AppConstants.statusCompleted && d.data()['status'] != AppConstants.statusCancelled)
          .length;
    }
  }

  /// Creates a new technician request using an idempotent pre-generated ID and appends the initial event.
  Future<void> createRequest(TechnicianRequestModel request) async {
    final docRef = _requestsRef.doc(request.id);

    // 1. Write the main request document
    await docRef.set(request.toMap());

    // 2. Append initial NEW event to technicianRequests/{id}/events
    try {
      await docRef.collection('events').add({
        'status': AppConstants.statusNew,
        'by': 'dentist',
        'at': Timestamp.fromDate(request.createdAt),
        'note': 'Ticket created and queued for technician dispatch',
      });
    } catch (_) {
      // Non-fatal if events collection has network delay
    }
  }

  /// Streams active requests for a specific dentist with in-memory sorting to avoid composite index failure.
  Stream<List<TechnicianRequestModel>> streamDentistRequests(String dentistId, {int limit = 50}) {
    return _requestsRef
        .where('dentistId', isEqualTo: dentistId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => TechnicianRequestModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Streams a single request document live for real-time status updates on details screen.
  Stream<TechnicianRequestModel?> streamRequest(String requestId) {
    return _requestsRef.doc(requestId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return TechnicianRequestModel.fromFirestore(snapshot);
    });
  }

  /// Streams audit events subcollection for the status timeline without requiring server-side composite indexes.
  Stream<List<RequestEvent>> streamRequestEvents(String requestId) {
    return _requestsRef
        .doc(requestId)
        .collection('events')
        .snapshots()
        .map((snapshot) {
      final list = <RequestEvent>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(RequestEvent.fromMap(doc.data()));
        } catch (_) {}
      }
      list.sort((a, b) => a.at.compareTo(b.at));
      return list;
    }).handleError((_) => <RequestEvent>[]);
  }

  /// Streams internal admin notes subcollection with in-memory sorting and graceful fallback.
  Stream<List<Map<String, dynamic>>> streamInternalNotes(String requestId) {
    return _requestsRef
        .doc(requestId)
        .collection('internal')
        .doc('notes')
        .collection('items')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((d) => d.data()).toList();
      list.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return list;
    }).handleError((_) => <Map<String, dynamic>>[]);
  }

  /// Appends an internal admin note to technicianRequests/{id}/internal/notes.
  Future<void> addInternalNote({
    required String requestId,
    required String note,
    required String authorEmail,
  }) async {
    final noteRef = _requestsRef
        .doc(requestId)
        .collection('internal')
        .doc('notes')
        .collection('items')
        .doc();
    await noteRef.set({
      'note': note.trim(),
      'author': authorEmail,
      'createdAt': Timestamp.now(),
    });
  }

  /// Assigns a technician to a request using a Firestore transaction.
  Future<void> assignTechnician({
    required String requestId,
    required String technicianId,
    required String technicianName,
    required String technicianPhone,
  }) async {
    final docRef = _requestsRef.doc(requestId);
    final eventRef = docRef.collection('events').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Request does not exist');
      }

      final currentStatus = snapshot.data()?['status'] as String? ?? '';
      if (!TechnicianRequestModel.canAdminAssign(currentStatus)) {
        throw Exception('Ticket cannot be assigned from status: $currentStatus');
      }

      final now = Timestamp.now();
      transaction.update(docRef, {
        'status': AppConstants.statusAssigned,
        'assignedTechnicianId': technicianId,
        'assignedTechnicianName': technicianName,
        'assignedTechnicianPhone': technicianPhone,
        'assignedAt': now,
        'updatedAt': now,
      });

      transaction.set(eventRef, {
        'status': AppConstants.statusAssigned,
        'by': 'admin',
        'at': now,
        'note': 'Assigned technician: $technicianName ($technicianPhone)',
      });
    });
  }

  /// Advances request to IN_PROGRESS (only valid when ASSIGNED and technician exists).
  Future<void> setInProgress({
    required String requestId,
  }) async {
    final docRef = _requestsRef.doc(requestId);
    final eventRef = docRef.collection('events').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Request does not exist');
      }

      final data = snapshot.data() ?? {};
      final currentStatus = data['status'] as String? ?? '';
      final hasTech = (data['assignedTechnicianId'] as String?)?.isNotEmpty == true;

      if (!TechnicianRequestModel.canAdminSetInProgress(status: currentStatus, hasTechnician: hasTech)) {
        throw Exception('Cannot set In Progress: must be ASSIGNED with an assigned technician.');
      }

      final now = Timestamp.now();
      transaction.update(docRef, {
        'status': AppConstants.statusInProgress,
        'startedAt': now,
        'updatedAt': now,
      });

      transaction.set(eventRef, {
        'status': AppConstants.statusInProgress,
        'by': 'admin',
        'at': now,
        'note': 'Technician is attending to the equipment',
      });
    });
  }

  /// Cancels a request (by Doctor or Admin) with mandatory reason.
  Future<void> cancelRequest({
    required String requestId,
    required String cancelledBy, // 'dentist' | 'admin'
    required String reasonCode,
    required String reasonText,
  }) async {
    final docRef = _requestsRef.doc(requestId);
    final eventRef = docRef.collection('events').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Request does not exist');
      }

      final currentStatus = snapshot.data()?['status'] as String? ?? '';
      if (cancelledBy == 'dentist') {
        if (!TechnicianRequestModel.canDoctorCancel(currentStatus)) {
          throw Exception('Doctors can cancel only when Pending or Assigned.');
        }
      } else {
        if (!TechnicianRequestModel.canAdminCancel(currentStatus)) {
          throw Exception('This ticket is in a final status and cannot be cancelled.');
        }
      }

      final now = Timestamp.now();
      transaction.update(docRef, {
        'status': AppConstants.statusCancelled,
        'cancelledAt': now,
        'cancelledBy': cancelledBy,
        'reasonCode': reasonCode,
        'reasonText': reasonText,
        'updatedAt': now,
      });

      transaction.set(eventRef, {
        'status': AppConstants.statusCancelled,
        'by': cancelledBy,
        'at': now,
        'note': 'Cancelled: $reasonText',
      });
    });
  }

  /// Completes and closes ticket with whole rupee amountPaid.
  Future<void> completeRequest({
    required String requestId,
    required double amountPaid,
    required String completedBy, // 'dentist' | 'admin'
  }) async {
    final docRef = _requestsRef.doc(requestId);
    final eventRef = docRef.collection('events').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Request does not exist');
      }

      final currentStatus = snapshot.data()?['status'] as String? ?? '';
      if (completedBy == 'dentist') {
        if (!TechnicianRequestModel.canDoctorComplete(currentStatus)) {
          throw Exception('Cannot mark completed from status: $currentStatus');
        }
      } else {
        if (!TechnicianRequestModel.canAdminCloseOnBehalf(currentStatus)) {
          throw Exception('Admin cannot close ticket from status: $currentStatus');
        }
      }

      final now = Timestamp.now();
      transaction.update(docRef, {
        'status': AppConstants.statusCompleted,
        'amountPaid': amountPaid,
        'completedAt': now,
        'completedBy': completedBy,
        'updatedAt': now,
      });

      transaction.set(eventRef, {
        'status': AppConstants.statusCompleted,
        'by': completedBy,
        'at': now,
        'note': 'Ticket closed. Amount paid: ₹${amountPaid.toInt()}',
      });
    });
  }

  /// Allows the doctor to update request details (e.g. wrong slot or wrong issue)
  /// while the ticket is still in an editable status (NEW or ASSIGNED).
  Future<void> updateDoctorRequest({
    required String requestId,
    required String issueCode,
    required String issueLabel,
    required String issueDescription,
    required String slotDate,
    required String slotKey,
    required DateTime slotStart,
    RequestAddress? address,
  }) async {
    final docRef = _requestsRef.doc(requestId);
    final eventRef = docRef.collection('events').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Request does not exist');
      }

      final currentStatus = snapshot.data()?['status'] as String? ?? '';
      if (currentStatus != AppConstants.statusNew && currentStatus != AppConstants.statusAssigned) {
        throw Exception('Request cannot be edited once technician has started or ticket is closed');
      }

      final now = Timestamp.now();
      final updates = <String, dynamic>{
        'issueCode': issueCode,
        'issueLabel': issueLabel,
        'issueDescription': issueDescription.trim(),
        'slotDate': slotDate,
        'slotKey': slotKey,
        'slotStart': Timestamp.fromDate(slotStart),
        'updatedAt': now,
      };

      if (address != null) {
        updates['address'] = address.toMap();
      }

      transaction.update(docRef, updates);

      // Audit event
      transaction.set(eventRef, {
        'status': currentStatus,
        'by': snapshot.data()?['dentistId'] ?? '',
        'role': 'dentist',
        'note': 'Details updated by doctor (Issue: $issueLabel, Slot: $slotDate)',
        'at': now,
      });
    });
  }

  // ── Scalable Admin Bookings & Aggregations ──────────────────────

  /// Fetches paginated requests for admin bookings table.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchAdminRequests({
    String? status,
    DocumentSnapshot? startAfterDoc,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _requestsRef;
    if (status != null && status.isNotEmpty && status != 'ALL') {
      query = query.where('status', isEqualTo: status);
    }
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    return await query.limit(limit).get();
  }

  /// Streams requests filtered by status with in-memory sorting by slotStart.
  /// Eliminates composite index requirement so all status tabs load instantly.
  Stream<List<TechnicianRequestModel>> streamAdminRequests({String? status, int limit = 50}) {
    Query<Map<String, dynamic>> query = _requestsRef;
    if (status != null && status.isNotEmpty && status != 'ALL') {
      query = query.where('status', isEqualTo: status);
    }
    return query.limit(limit).snapshots().map((snap) {
      final list = snap.docs.map((d) => TechnicianRequestModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Real-time stream of all requests for executive dashboard calculations.
  Stream<List<TechnicianRequestModel>> streamAllRequests({int limit = 100}) {
    return _requestsRef.limit(limit).snapshots().map((snap) {
      final list = snap.docs.map((d) => TechnicianRequestModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Real-time stream of requests count for a given status.
  Stream<int> streamStatusCount(String status) {
    return _requestsRef
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Gets count of requests for a given status using Firestore aggregation query.
  Future<int> getStatusCount(String status) async {
    try {
      final agg = await _requestsRef.where('status', isEqualTo: status).count().get();
      return agg.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Real-time stream of total reported payments to technicians in Rs.
  Stream<double> streamTotalAmountPaid() {
    return _requestsRef
        .where('status', isEqualTo: AppConstants.statusCompleted)
        .snapshots()
        .map((snap) {
      double total = 0.0;
      for (final doc in snap.docs) {
        final amount = (doc.data()['amountPaid'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }
      return total;
    });
  }

  /// Calculates total reported payments to technicians using completed requests.
  Future<double> getTotalAmountPaid() async {
    try {
      final snap = await _requestsRef.where('status', isEqualTo: AppConstants.statusCompleted).get();
      double total = 0.0;
      for (final doc in snap.docs) {
        final amount = (doc.data()['amountPaid'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }
      return total;
    } catch (_) {
      return 0.0;
    }
  }

  /// Fetches requests needing immediate executive attention per Section 3.8:
  /// - Pending > 2 hours
  /// - Today's slot with no technician
  /// - Slot passed but still ASSIGNED
  /// - ASSIGNED or IN_PROGRESS > 48 hours
  Future<List<TechnicianRequestModel>> fetchNeedsAttention() async {
    try {
      final now = DateTime.now();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      final fortyEightHoursAgo = now.subtract(const Duration(hours: 48));

      final activeSnap = await _requestsRef
          .where('status', whereIn: [
            AppConstants.statusNew,
            AppConstants.statusAssigned,
            AppConstants.statusInProgress,
          ])
          .get();

      final results = <TechnicianRequestModel>[];
      for (final doc in activeSnap.docs) {
        final req = TechnicianRequestModel.fromFirestore(doc);
        bool needsAttention = false;

        if (req.isNew && req.createdAt.isBefore(twoHoursAgo)) {
          needsAttention = true;
        } else if (req.isNew && req.slotStart.year == now.year && req.slotStart.month == now.month && req.slotStart.day == now.day) {
          needsAttention = true;
        } else if (req.isAssigned && req.slotStart.isBefore(now)) {
          needsAttention = true;
        } else if ((req.isAssigned || req.isInProgress) && req.createdAt.isBefore(fortyEightHoursAgo)) {
          needsAttention = true;
        }

        if (needsAttention) {
          results.add(req);
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  CollectionReference<Map<String, dynamic>> get _settlementsRef =>
      _firestore.collection('riodent_settlements');

  /// Streams real-time RioDent Share accounting summary:
  /// - RioDent Share = 10% of each eligible amount paid to doctor
  /// - Technician payment remains intact and separate
  /// - Settlements are recorded in 'riodent_settlements'
  Stream<RioDentShareSummary> streamRioDentShareSummary() {
    return _requestsRef
        .where('status', isEqualTo: AppConstants.statusCompleted)
        .snapshots()
        .asyncMap((requestsSnap) async {
      double totalDoctorPaid = 0.0;
      final bills = <RioDentBillRecord>[];
      final eligibleDocs = requestsSnap.docs.where((d) {
        final amount = (d.data()['amountPaid'] as num?)?.toDouble() ?? 0.0;
        return amount > 0;
      }).toList();

      for (final doc in eligibleDocs) {
        final data = doc.data();
        final doctorPaid = (data['amountPaid'] as num?)?.toDouble() ?? 0.0;
        final techPayment = (data['technicianPayment'] as num?)?.toDouble() ??
            (data['amountPaidToTechnician'] as num?)?.toDouble() ??
            (doctorPaid * 0.6);
        final share = doctorPaid * 0.10; // strictly 10% of doctor payment
        totalDoctorPaid += doctorPaid;

        final isSettled = data['shareSettled'] == true;
        final settlementId = data['settlementId'] as String?;
        final settledAt = (data['shareSettledAt'] as Timestamp?)?.toDate();

        DateTime billDate = DateTime.now();
        if (data['completedAt'] is Timestamp) {
          billDate = (data['completedAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is Timestamp) {
          billDate = (data['createdAt'] as Timestamp).toDate();
        }

        bills.add(RioDentBillRecord(
          ticketId: doc.id,
          displayTicketId: (data['ticketNumber'] as String?)?.isNotEmpty == true
              ? data['ticketNumber'] as String
              : 'REQ-${doc.id.substring(0, doc.id.length >= 6 ? 6 : doc.id.length).toUpperCase()}',
          doctorId: data['dentistId'] as String? ?? '',
          doctorName: data['dentistName'] as String? ?? 'Doctor',
          clinicName: data['clinicName'] as String? ?? 'Clinic',
          doctorPaymentAmount: doctorPaid,
          technicianPaymentAmount: techPayment,
          shareRate: 0.10,
          calculatedShare: share,
          paymentStatus: 'PAID',
          billDate: billDate,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? billDate,
          isSettled: isSettled,
          settlementId: settlementId,
          settledAt: settledAt,
        ));
      }

      // Query settlements
      double totalSettled = 0.0;
      RioDentSettlementModel? latest;
      try {
        final settlementsSnap = await _settlementsRef.orderBy('settledAt', descending: true).get();
        if (settlementsSnap.docs.isNotEmpty) {
          latest = RioDentSettlementModel.fromFirestore(settlementsSnap.docs.first);
          for (final sDoc in settlementsSnap.docs) {
            totalSettled += (sDoc.data()['amountSettled'] as num?)?.toDouble() ?? 0.0;
          }
        }
      } catch (_) {}

      final totalShareEarned = totalDoctorPaid * 0.10;
      final unsettledShare = (totalShareEarned - totalSettled).clamp(0.0, double.infinity);

      // Sort bills by billDate descending
      bills.sort((a, b) => b.billDate.compareTo(a.billDate));

      return RioDentShareSummary(
        totalDoctorPaid: totalDoctorPaid,
        totalShareEarned: totalShareEarned,
        totalShareSettled: totalSettled,
        unsettledShare: unsettledShare,
        eligibleBillsCount: bills.length,
        latestSettlement: latest,
        bills: bills,
      );
    });
  }

  /// Streams settlement history for admin review.
  Stream<List<RioDentSettlementModel>> streamSettlements() {
    return _settlementsRef.orderBy('settledAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((d) => RioDentSettlementModel.fromFirestore(d)).toList();
    });
  }

  /// Concurrency-safe atomic settlement of eligible outstanding RioDent Share.
  Future<void> settleRioDentShare({
    required double amountToSettle,
    required String adminEmail,
    required List<String> requestIds,
    String? notes,
  }) async {
    if (amountToSettle <= 0) {
      throw Exception('Settlement amount must be greater than zero.');
    }

    final settlementDoc = _settlementsRef.doc();
    final now = Timestamp.now();

    final batch = _firestore.batch();

    // 1. Create settlement record
    batch.set(settlementDoc, {
      'amountSettled': amountToSettle,
      'billCount': requestIds.length,
      'requestIds': requestIds,
      'settledBy': adminEmail,
      'settledAt': now,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

    // 2. Mark included requests as settled
    for (final reqId in requestIds) {
      final reqRef = _requestsRef.doc(reqId);
      batch.update(reqRef, {
        'shareSettled': true,
        'shareSettledAt': now,
        'settlementId': settlementDoc.id,
      });
    }

    await batch.commit();
  }
}

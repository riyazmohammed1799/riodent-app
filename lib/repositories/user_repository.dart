import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Repository managing user data in Cloud Firestore.
/// Roles are not stored in the user document and cannot be escalated by clients.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Streams the profile for a given [uid].
  Stream<UserModel?> streamUser(String uid, {bool isAdmin = false}) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserModel.fromFirestore(snapshot, isAdmin: isAdmin);
    });
  }

  /// Fetches the profile for a given [uid] once.
  Future<UserModel?> getUser(String uid, {bool isAdmin = false}) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserModel.fromFirestore(doc, isAdmin: isAdmin);
  }

  /// Creates a new doctor profile on initial registration or first-time Google sign-in.
  Future<void> createUser({
    required String uid,
    String? phone,
    String? displayName,
    String? email,
    String? clinicName,
    String? clinicAddress,
  }) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) {
      final now = DateTime.now();
      final user = UserModel(
        uid: uid,
        displayName: displayName ?? 'Doctor',
        phone: phone ?? '',
        email: email,
        clinicName: clinicName ?? '',
        clinicAddress: clinicAddress ?? '',
        isAdmin: false,
        createdAt: now,
        updatedAt: now,
      );
      await _usersRef.doc(uid).set(user.toMap());
    }
  }

  /// Updates profile information for a dentist.
  Future<void> updateDentistProfile({
    required String uid,
    required String displayName,
    required String clinicName,
    required String clinicAddress,
    String? phone,
    double? clinicLatitude,
    double? clinicLongitude,
    String? email,
  }) async {
    final data = <String, dynamic>{
      'displayName': displayName.trim(),
      'clinicName': clinicName.trim(),
      'clinicAddress': clinicAddress.trim(),
      'updatedAt': Timestamp.now(),
    };
    if (phone != null && phone.isNotEmpty) data['phone'] = phone.trim();
    if (clinicLatitude != null) data['clinicLatitude'] = clinicLatitude;
    if (clinicLongitude != null) data['clinicLongitude'] = clinicLongitude;
    if (email != null && email.isNotEmpty) data['email'] = email.trim();

    await _usersRef.doc(uid).set(data, SetOptions(merge: true));
  }

  /// In-app account deletion: deletes/anonymizes user personal data per Play Store & DPDP requirements.
  Future<void> deleteUserAccount(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  /// Streams registered dentists with pagination limit for scalability (1 lakh doctors).
  Stream<List<UserModel>> streamRecentDentists({int limit = 20}) {
    return _usersRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  /// Fetches paginated registered doctors for admin directory.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchDentists({
    DocumentSnapshot? startAfterDoc,
    int limit = 20,
  }) async {
    var query = _usersRef.orderBy('createdAt', descending: true).limit(limit);
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    return await query.get();
  }

  /// Live real-time stream of registered doctors count.
  Stream<int> streamDentistCount() {
    return _usersRef.snapshots().map((snap) => snap.docs.length);
  }

  /// Gets total registered doctors count using Firestore aggregation query.
  Future<int> getDentistCount() async {
    try {
      final aggregate = await _usersRef.count().get();
      return aggregate.count ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

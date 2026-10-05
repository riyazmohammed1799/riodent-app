import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Repository managing user data in Cloud Firestore.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  /// Streams the profile for a given [uid].
  Stream<UserModel?> streamUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return UserModel.fromFirestore(snapshot);
    });
  }

  /// Streams all registered dentists for the admin directory.
  Stream<List<UserModel>> streamAllDentists() {
    return _usersRef
        .where('role', isEqualTo: AppConstants.roleDentist)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetches the profile for a given [uid] once.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserModel.fromFirestore(doc);
  }

  /// Creates a new user profile on initial sign-in.
  Future<void> createUser({
    required String uid,
    required String phone,
    String? displayName,
    String? email,
    String role = AppConstants.roleDentist,
  }) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) {
      final now = DateTime.now();
      final user = UserModel(
        uid: uid,
        displayName: displayName ?? '',
        phone: phone,
        email: email,
        role: role,
        profileComplete: false,
        createdAt: now,
        updatedAt: now,
      );
      await _usersRef.doc(uid).set(user.toMap());
    }
  }

  /// Ensures an admin profile exists in Firestore.
  Future<void> ensureAdminProfile({
    required String uid,
    required String email,
  }) async {
    final now = DateTime.now();
    await _usersRef.doc(uid).set({
      'uid': uid,
      'displayName': 'RioDent Operations Admin',
      'email': email,
      'phone': '+918000000000',
      'role': AppConstants.roleAdmin,
      'profileComplete': true,
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  /// Updates profile information for a dentist.
  Future<void> updateDentistProfile({
    required String uid,
    required String displayName,
    required String clinicName,
    required String clinicAddress,
    double? clinicLatitude,
    double? clinicLongitude,
    String? email,
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'displayName': displayName.trim(),
      'clinicName': clinicName.trim(),
      'clinicAddress': clinicAddress.trim(),
      'profileComplete': true,
      'role': AppConstants.roleDentist,
      'updatedAt': Timestamp.now(),
    };
    if (clinicLatitude != null) data['clinicLatitude'] = clinicLatitude;
    if (clinicLongitude != null) data['clinicLongitude'] = clinicLongitude;
    if (email != null && email.isNotEmpty) data['email'] = email.trim();

    await _usersRef.doc(uid).set(data, SetOptions(merge: true));
  }
}

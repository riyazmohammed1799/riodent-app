import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_config_model.dart';
import '../utils/constants.dart';

/// Repository managing application configuration from Firestore.
class SettingsRepository {
  final FirebaseFirestore _firestore;

  SettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _configDoc => _firestore
      .collection(AppConstants.appSettingsCollection)
      .doc(AppConstants.bookingConfigDoc);

  /// Streams the booking configuration. Falls back to default if doc does not exist.
  Stream<BookingConfigModel> streamBookingConfig() {
    return _configDoc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return BookingConfigModel.defaultConfig();
      }
      return BookingConfigModel.fromFirestore(snapshot);
    });
  }

  /// Fetches booking configuration once.
  Future<BookingConfigModel> getBookingConfig() async {
    try {
      final doc = await _configDoc.get();
      if (!doc.exists || doc.data() == null) {
        return BookingConfigModel.defaultConfig();
      }
      return BookingConfigModel.fromFirestore(doc);
    } catch (_) {
      return BookingConfigModel.defaultConfig();
    }
  }

  /// Updates booking configuration in Firestore (admin only).
  Future<void> updateBookingConfig(BookingConfigModel config) async {
    await _configDoc.set(config.toMap(), SetOptions(merge: true));
  }

  /// Ensures default configuration exists in Firestore.
  Future<void> ensureInitialConfig() async {
    final doc = await _configDoc.get();
    if (!doc.exists) {
      await _configDoc.set(BookingConfigModel.defaultConfig().toMap());
    }
  }
}

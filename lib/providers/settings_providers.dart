import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_config_model.dart';
import '../repositories/settings_repository.dart';
import 'user_providers.dart';

/// Provider for SettingsRepository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SettingsRepository(firestore: firestore);
});

/// Stream of booking configuration settings from Firestore.
final bookingConfigProvider = StreamProvider<BookingConfigModel>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.streamBookingConfig();
});

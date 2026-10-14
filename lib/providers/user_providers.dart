import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// Provider for Cloud Firestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for UserRepository.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserRepository(firestore: firestore);
});

/// Stream provider for recent registered dentists (limited to 20 for scalability).
final registeredDentistsProvider = StreamProvider<List<UserModel>>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.streamRecentDentists(limit: 50);
});

/// Future provider for total count of registered dentists using Firestore aggregate count().
final dentistCountProvider = FutureProvider<int>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.getDentistCount();
});

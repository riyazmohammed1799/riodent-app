import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../utils/constants.dart';
import 'user_providers.dart';

/// Provider for FirebaseAuth instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRepository(firebaseAuth: firebaseAuth);
});

/// Stream of authentication state changes (Firebase User).
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Provider for the current user's UID (null if unauthenticated).
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.uid;
});

/// Stream provider for the logged-in user's Firestore profile.
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.streamUser(user.uid);
});

/// Provider for the current user's role string.
final userRoleProvider = Provider<String?>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.value?.role;
});

/// Convenience provider: true if the current user is a dentist.
final isDentistProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == AppConstants.roleDentist;
});

/// Convenience provider: true if the current user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == AppConstants.roleAdmin;
});

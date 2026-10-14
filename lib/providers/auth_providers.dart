import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
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

/// Checks if current user has custom claim admin == true.
final adminClaimProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return false;
  final authRepo = ref.watch(authRepositoryProvider);
  return await authRepo.checkIsAdminClaim();
});

/// Stream provider for the logged-in user's Firestore profile.
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  if (user == null) {
    return Stream.value(null);
  }

  final isAdmin = ref.watch(adminClaimProvider).value ?? false;
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.streamUser(user.uid, isAdmin: isAdmin);
});

/// Convenience provider: true if the current user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(adminClaimProvider).value ?? false;
});

/// Convenience provider: true if the current user is a dentist.
final isDentistProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  final isAdmin = ref.watch(isAdminProvider);
  return !isAdmin;
});

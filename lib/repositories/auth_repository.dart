import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Repository handling authentication flows for dentists and admin.
/// Admin privileges are governed by Firebase custom claims ('admin': true).
/// All demo credentials, 1-click test buttons, and phone OTP are removed per specification.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    if (!kIsWeb) {
      try {
        GoogleSignIn.instance.initialize();
      } catch (_) {
        // Initialization can fail in mock or test environments
      }
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Returns true if current authenticated user has the Firebase custom claim admin: true.
  Future<bool> checkIsAdminClaim([bool forceRefresh = false]) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    try {
      final tokenResult = await user.getIdTokenResult(forceRefresh);
      return tokenResult.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Signs in a user using Google Sign-In.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final authProvider = GoogleAuthProvider();
      return await _firebaseAuth.signInWithPopup(authProvider);
    } else {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
    }
  }

  /// Signs in a user using Email and Password.
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a new doctor using Email and Password.
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Send email verification asynchronously without blocking doctor workflow
    try {
      await cred.user?.sendEmailVerification();
    } catch (_) {}
    return cred;
  }

  /// Sends a password reset email to [email].
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Permanently deletes the current user's authentication account.
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
      await user.delete();
    }
  }

  /// Signs out the current user and clears session state.
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _firebaseAuth.signOut();
  }
}

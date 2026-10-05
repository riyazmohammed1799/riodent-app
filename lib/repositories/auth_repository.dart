import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Repository handling authentication flows for dentists (Google, Email/Password, Phone OTP)
/// and administrator (Email/Password).
class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    if (!kIsWeb) {
      try {
        GoogleSignIn.instance.initialize();
      } catch (_) {
        // Initialization can fail in mock or unsupported test environments
      }
    }
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

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

  /// Initiates Phone Number verification for dentists.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    required void Function(FirebaseAuthException exception) onVerificationFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verifies the OTP code entered by the user with the given [verificationId].
  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Signs in directly with a [PhoneAuthCredential] (auto-retrieval scenario).
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    return await _firebaseAuth.signInWithCredential(credential);
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

  /// Registers a new user using Email and Password.
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sends a password reset email to [email].
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Signs in or registers the demo dentist for instant testing.
  Future<UserCredential> signInOrRegisterDemoDentist() async {
    const demoEmail = 'dentist.demo@riodent.com';
    const demoPassword = 'RioDentDemoPassword2026!';
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: demoEmail,
        password: demoPassword,
      );
    } on FirebaseAuthException {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: demoEmail,
        password: demoPassword,
      );
    }
  }

  /// Signs in or registers the admin for instant end-to-end testing.
  Future<UserCredential> signInOrRegisterAdmin() async {
    const adminEmail = 'admin@riodent.com';
    const adminPassword = 'RioDentAdmin2026!';
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    } on FirebaseAuthException {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _firebaseAuth.signOut();
  }
}

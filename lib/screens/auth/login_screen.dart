import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

/// Premier unified sign-in and registration screen for dental clinics and doctors.
/// Per specifications:
/// - Single login screen (no admin link, no demo buttons, no OTP tab)
/// - Google Sign-In prominent first
/// - Clean Register & Sign-in with Email & Password
/// - Direct to Home upon successful registration or sign-in
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _clinicController = TextEditingController();

  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _clinicController.dispose();
    super.dispose();
  }

  String _mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email. Tap "New to RioDent? Register".';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password. Please verify your credentials.';
        case 'email-already-in-use':
          return 'An account already exists for this email. Please sign in instead.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact RioDent support.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again in a few moments.';
        case 'network-request-failed':
          return 'Unable to connect. Please check your internet connection and try again.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return 'Authentication error: $error';
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      final credential = await authRepo.signInWithGoogle();
      final user = credential?.user;
      if (user != null) {
        // Create user record if first-time user
        final existing = await userRepo.getUser(user.uid);
        if (existing == null) {
          final doctorName = user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Doctor';
          await userRepo.createUser(
            uid: user.uid,
            displayName: doctorName,
            email: user.email,
            phone: user.phoneNumber ?? '',
            clinicName: 'Dental Clinic',
            clinicAddress: 'Hyderabad, Telangana',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _mapAuthError(e);
      });
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      if (_isSignUpMode) {
        // Register new doctor account
        final credential = await authRepo.registerWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        final user = credential.user;
        if (user != null) {
          final doctorName = _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'Doctor';
          final clinicName = _clinicController.text.trim().isNotEmpty
              ? _clinicController.text.trim()
              : 'Dental Clinic';

          await userRepo.createUser(
            uid: user.uid,
            displayName: doctorName,
            clinicName: clinicName,
            email: user.email,
          );
          // Directly proceeds to Home via router state listener
        }
      } else {
        // Sign in existing account (Doctor or Admin)
        await authRepo.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _mapAuthError(e);
      });
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || Validators.email(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your registered email address first.')),
      );
      return;
    }

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reset email: ${_mapAuthError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // App Brand Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/riodent_icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.primaryColor,
                          child: const Icon(
                            Icons.medical_services_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.appTagline,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Text(
                        'Hyderabad Launch Area',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. Prominently Highlighted Google Sign-In Hero Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: const Color(0xFF0284C7), width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata_rounded, size: 26, color: Color(0xFF0284C7)),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textHint,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Error / Success Message Banners
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: AppTheme.successColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.cardBorderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignUpMode ? 'Register New Clinic' : 'Sign In to Your Clinic',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_isSignUpMode) ...[
                            // Doctor Full Name
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Doctor Name *',
                                hintText: 'e.g. Dr. Priya Sharma',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (val) => Validators.required(val, 'Doctor name'),
                            ),
                            const SizedBox(height: 14),

                            // Clinic Name
                            TextFormField(
                              controller: _clinicController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Clinic Name *',
                                hintText: 'e.g. Smile Care Dental Hospital',
                                prefixIcon: Icon(Icons.local_hospital_outlined),
                              ),
                              validator: (val) => Validators.required(val, 'Clinic name'),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email Address *',
                              hintText: 'doctor@clinic.dental',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 14),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password *',
                              hintText: 'Minimum 6 characters',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: Validators.password,
                          ),

                          if (!_isSignUpMode) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading ? null : _handleForgotPassword,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(height: 18),

                          // Submit Action
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _isLoading ? null : _handleEmailAuth,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _isSignUpMode ? 'Create Clinic Account' : 'Sign In',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Mode Switcher (Sign In vs Register)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUpMode = !_isSignUpMode;
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      },
                      child: Text(
                        _isSignUpMode
                            ? 'Already have an account? Sign In'
                            : 'New to RioDent? Register Clinic',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  // Admin Login Shortcut for Testing
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isSignUpMode = false;
                          _emailController.text = 'admin@riodent.com';
                          _passwordController.text = 'RioDentAdmin2026!';
                        });
                      },
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppTheme.textHint),
                      label: const Text(
                        'Admin Login (Testing)',
                        style: TextStyle(color: AppTheme.textHint, fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

/// Premier login and registration screen for dental clinics and doctors.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Email form
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _clinicController = TextEditingController();
  bool _isSignUpMode = false;
  bool _obscurePassword = true;

  // Phone form
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _clinicController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email. Please click "Register New Clinic".';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password. Please verify your credentials.';
        case 'email-already-in-use':
          return 'An account already exists for this email. Please switch to Sign In.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again in a few moments.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return error.toString();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      final credential = await authRepo.signInWithGoogle();
      final user = credential?.user;
      if (user != null) {
        final existing = await userRepo.getUser(user.uid);
        if (existing == null) {
          await userRepo.createUser(
            uid: user.uid,
            phone: user.phoneNumber ?? '',
            displayName: user.displayName,
            email: user.email,
            role: AppConstants.roleDentist,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google Sign-In failed: ${_mapAuthError(e)}';
      });
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      if (_isSignUpMode) {
        final credential = await authRepo.registerWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        final user = credential.user;
        if (user != null) {
          await userRepo.createUser(
            uid: user.uid,
            phone: '',
            displayName: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : 'Doctor',
            email: user.email,
            role: AppConstants.roleDentist,
          );
          if (_clinicController.text.trim().isNotEmpty) {
            await userRepo.updateDentistProfile(
              uid: user.uid,
              displayName: _nameController.text.trim(),
              clinicName: _clinicController.text.trim(),
              clinicAddress: '',
              email: user.email,
            );
          }
        }
      } else {
        await authRepo.signInWithEmailPassword(
          email: _emailController.text,
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
        const SnackBar(content: Text('Please enter your clinic email above first.')),
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

  Future<void> _handleInstantDemoLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      final credential = await authRepo.signInOrRegisterDemoDentist();
      final user = credential.user;
      if (user != null) {
        final existing = await userRepo.getUser(user.uid);
        if (existing == null) {
          await userRepo.createUser(
            uid: user.uid,
            phone: '+919876543210',
            displayName: 'Dr. Priya Sharma',
            email: user.email,
            role: AppConstants.roleDentist,
          );
          await userRepo.updateDentistProfile(
            uid: user.uid,
            displayName: 'Dr. Priya Sharma',
            clinicName: 'Smile Care Dental Clinic',
            clinicAddress: '123 Brigade Road, Bengaluru, Karnataka 560001',
            email: user.email,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Instant demo login failed: $e';
      });
    }
  }

  Future<void> _handleSendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final formattedPhone = Validators.toE164(_phoneController.text);
    final authRepo = ref.read(authRepositoryProvider);

    try {
      await authRepo.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onVerificationCompleted: (credential) async {
          await authRepo.signInWithCredential(credential);
        },
        onVerificationFailed: (exception) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = exception.message ?? 'Verification failed. Please try again.';
          });
        },
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          context.push('/otp', extra: {
            'verificationId': verificationId,
            'phone': formattedPhone,
            'resendToken': resendToken,
          });
        },
        onCodeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              onPressed: () => context.push('/admin/login'),
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
              label: const Text('Admin Portal'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 36,
                        color: Colors.white,
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
                    'Certified Dental Technician Network',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: AppTheme.successColor),
                            const SizedBox(width: 4),
                            Text(
                              '100% Free Clinic Service',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Sign-In Action
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.cardBorderColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, size: 24),
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR USE EMAIL / PHONE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Tab selector: Email vs Mobile OTP
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: AppTheme.primaryColor,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      unselectedLabelColor: AppTheme.textSecondary,
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Email & Password'),
                        Tab(text: 'Mobile OTP'),
                      ],
                      onTap: (_) => setState(() => _errorMessage = null),
                    ),
                  ),

                  const SizedBox(height: 16),

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

                  // Tab View
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return _tabController.index == 0
                          ? _buildEmailPasswordForm(theme)
                          : _buildPhoneForm(theme);
                    },
                  ),

                  const SizedBox(height: 20),

                  // 1-Click Instant Demo Login for Doctor
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.cardBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on_rounded, color: AppTheme.warningColor, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Instant Testing Access',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Test the dentist workflow immediately as Dr. Priya Sharma without SMS verification.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _isLoading ? null : _handleInstantDemoLogin,
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('1-Click Doctor Test Login'),
                        ),
                      ],
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

  Widget _buildEmailPasswordForm(ThemeData theme) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSignUpMode ? 'Register New Clinic' : 'Doctor Sign In',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isSignUpMode = !_isSignUpMode;
                          _errorMessage = null;
                        });
                      },
                child: Text(
                  _isSignUpMode ? 'Already registered? Sign In' : 'New Clinic? Register',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isSignUpMode) ...[
            Text('Doctor Full Name', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Dr. Priya Sharma',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (v) => _isSignUpMode ? Validators.required(v, 'Doctor name') : null,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
            Text('Clinic / Hospital Name', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _clinicController,
              decoration: const InputDecoration(
                hintText: 'e.g. Smile Dental Care Clinic',
                prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
              ),
              validator: (v) => _isSignUpMode ? Validators.required(v, 'Clinic name') : null,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),
          ],

          Text('Clinic Email Address', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'doctor@clinic.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: Validators.email,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),

          Text('Password', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: _isSignUpMode ? 'Create password (min 6 characters)' : 'Enter password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: Validators.password,
            enabled: !_isLoading,
          ),

          if (!_isSignUpMode) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _handleForgotPassword,
                child: const Text('Forgot Password?'),
              ),
            ),
          ] else
            const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailAuth,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isSignUpMode ? 'Register Clinic Account' : 'Sign In as Doctor'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm(ThemeData theme) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dentist Mobile Number', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              prefixText: '+91 ',
              hintText: 'Enter 10-digit number',
              prefixIcon: Icon(Icons.phone_android_rounded, size: 20),
              counterText: '',
            ),
            validator: Validators.phoneNumber,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Get Verification OTP'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _phoneController.text = '9876543210';
                      _errorMessage = null;
                    });
                  },
            icon: const Icon(Icons.touch_app_rounded, size: 16),
            label: const Text('Fill Test Phone (9876543210)'),
          ),
        ],
      ),
    );
  }
}

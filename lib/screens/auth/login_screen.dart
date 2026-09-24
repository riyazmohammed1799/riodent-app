import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

/// Screen for dentist phone number entry and OTP dispatch.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

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
          // Auto-retrieval scenario
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
        onCodeAutoRetrievalTimeout: (verificationId) {
          // Auto-retrieval timed out
        },
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
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.push('/admin/login'),
            child: const Text('Admin Login'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(
                  Icons.medical_services_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to ${AppConstants.appName}',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fast, reliable dental technician services at your clinic.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Text(
                  'Dentist Mobile Number',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    prefixText: '+91 ',
                    hintText: 'Enter 10-digit number',
                    prefixIcon: Icon(Icons.phone_android_rounded),
                    counterText: '',
                  ),
                  validator: Validators.phoneNumber,
                  enabled: !_isLoading,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Get OTP'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _phoneController.text = '9876543210';
                            _errorMessage = null;
                          });
                        },
                  icon: const Icon(Icons.touch_app_rounded, size: 18),
                  label: const Text('Fill Test Number (9876543210)'),
                ),
                const SizedBox(height: 24),
                Text(
                  'By proceeding, you agree to receive an SMS verification code.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

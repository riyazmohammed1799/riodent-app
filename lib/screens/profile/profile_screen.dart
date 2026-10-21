import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'package:url_launcher/url_launcher.dart';

/// Minimal doctor profile screen with theme switching, service history summary,
/// clinic profile editing, support desk, and Google Play-compliant account deletion.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _clinicController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool _isInit = false;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final user = ref.read(currentUserProfileProvider).value;
      _nameController = TextEditingController(text: user?.displayName ?? '');
      final initialClinic = (user?.clinicName != null &&
              user!.clinicName!.trim().isNotEmpty &&
              user.clinicName != 'Dental Clinic')
          ? user.clinicName!
          : '';
      _clinicController = TextEditingController(text: initialClinic);
      _phoneController = TextEditingController(text: user?.phone ?? '');
      final initialAddress = (user?.clinicAddress != null &&
              user!.clinicAddress!.trim().isNotEmpty &&
              user.clinicAddress != 'Hyderabad, Telangana' &&
              user.clinicAddress != 'Hyderabad')
          ? user.clinicAddress!
          : '';
      _addressController = TextEditingController(text: initialAddress);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clinicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(userRepositoryProvider).updateDentistProfile(
        uid: user.uid,
        displayName: _nameController.text.trim(),
        clinicName: _clinicController.text.trim(),
        clinicAddress: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successColor,
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of RioDent?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(authStateProvider);
      ref.invalidate(adminClaimProvider);
      ref.invalidate(dentistRequestsProvider);
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final user = ref.read(currentUserProfileProvider).value;
    final currentAuthUser = ref.read(authRepositoryProvider).currentUser;
    if (user == null && currentAuthUser == null) return;
    final uid = user?.uid ?? currentAuthUser?.uid;
    if (uid == null) return;

    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Delete Account?'),
          ],
        ),
        content: const Text(
          'This action is permanent. All your clinic details, personal profile, and active bookings will be immediately and irreversibly deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    if (!mounted) return;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Are you completely sure you want to delete your RioDent account right now? You will be signed out immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Account'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Delete My Account'),
          ),
        ],
      ),
    );

    if (confirm2 == true) {
      try {
        setState(() => _isSaving = true);

        // 1. Delete user profile & clinic details from Firestore
        try {
          await ref.read(userRepositoryProvider).deleteUserAccount(uid);
        } catch (e) {
          debugPrint('Error deleting Firestore user document: $e');
        }

        // 2. Permanently delete Firebase Auth user account
        try {
          await ref.read(authRepositoryProvider).deleteAccount();
        } catch (e) {
          debugPrint('Error deleting Firebase Auth user account: $e');
        }

        // 3. Guarantee sign out of Firebase Auth and Google Sign In
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (e) {
          debugPrint('Error signing out: $e');
        }

        // 4. Invalidate all Riverpod session providers
        ref.invalidate(currentUserProfileProvider);
        ref.invalidate(authStateProvider);
        ref.invalidate(adminClaimProvider);
        ref.invalidate(dentistRequestsProvider);

        // 5. Navigate directly to /login page with zero access to home page
        if (mounted) {
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account permanently deleted. You have been signed out.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } catch (e) {
        // Fallback guarantee: ensure sign out and routing to /login always happens
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (_) {}
        ref.invalidate(currentUserProfileProvider);
        ref.invalidate(authStateProvider);
        if (mounted) {
          context.go('/login');
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final configAsync = ref.watch(bookingConfigProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final requestsAsync = ref.watch(dentistRequestsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final supportPhone = configAsync.value?.supportPhone ?? '+91 98765 43210';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic Profile'),
        leading: BackButton(
          onPressed: () {
            final authUser = ref.read(authRepositoryProvider).currentUser;
            final profile = ref.read(currentUserProfileProvider).value;
            if (authUser == null || profile == null) {
              context.go('/login');
              return;
            }
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dentist');
            }
          },
        ),
        actions: [
          if (userAsync.value?.email?.toLowerCase().trim() == 'riyaz.mohammed1799@gmail.com')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryColor),
              tooltip: 'Admin Portal',
              onPressed: () => context.go('/admin'),
            ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          final authUser = ref.read(authRepositoryProvider).currentUser;
          final profile = ref.read(currentUserProfileProvider).value;
          if (authUser == null || profile == null) {
            context.go('/login');
            return;
          }
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dentist');
          }
        },
        child: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                try {
                  context.go('/login');
                } catch (_) {}
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          final allRequests = requestsAsync.value ?? [];
          final totalCount = allRequests.length;
          final completedCount = allRequests
              .where((r) => r.status.toUpperCase() == 'COMPLETED')
              .length;
          final activeCount = allRequests
              .where((r) =>
                  r.status.toUpperCase() != 'COMPLETED' &&
                  r.status.toUpperCase() != 'CANCELLED')
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Doctor Profile Overview Card
                Card(

                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: isDark
                                  ? const Color(0xFF0369A1)
                                  : AppTheme.primaryLight,
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName.substring(0, 1).toUpperCase()
                                    : 'D',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName.isNotEmpty
                                        ? 'Dr. ${user.displayName}'
                                        : 'Doctor',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (user.clinicName != null &&
                                            user.clinicName!.trim().isNotEmpty &&
                                            user.clinicName != 'Dental Clinic')
                                        ? user.clinicName!
                                        : 'Clinic name not set',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF2DD4BF)
                                          : AppTheme.secondaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.phone.isNotEmpty ? user.phone : (user.email ?? ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: _isEditing ? 'Cancel Edit' : 'Edit Details',
                              icon: Icon(
                                _isEditing ? Icons.close : Icons.edit_outlined,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isEditing = !_isEditing;
                                });
                              },
                            ),
                          ],
                        ),

                        // Expandable Edit Form
                        if (_isEditing) ...[
                          const Divider(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Doctor Name *',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (val) => Validators.required(val, 'Doctor name'),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _clinicController,
                                  decoration: const InputDecoration(
                                    labelText: 'Clinic Name *',
                                    prefixIcon: Icon(Icons.local_hospital_outlined),
                                  ),
                                  validator: (val) => Validators.required(val, 'Clinic name'),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Mobile (10 digits) *',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                    counterText: '',
                                  ),
                                  validator: Validators.phoneNumber,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _addressController,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Clinic Address',
                                    prefixIcon: Icon(Icons.location_on_outlined),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton(
                                  onPressed: _isSaving ? null : _handleSaveProfile,
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save Profile Changes'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Service History Section (Requested by user)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 20,
                              color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Service History',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/dentist/requests'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('View All', style: TextStyle(fontSize: 13)),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 11),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                label: 'Total Services',
                                count: '$totalCount',
                                color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                                context: context,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricTile(
                                label: 'Active',
                                count: '$activeCount',
                                color: const Color(0xFF0284C7),
                                context: context,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricTile(
                                label: 'Completed',
                                count: '$completedCount',
                                color: AppTheme.successColor,
                                context: context,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Theme Mode Settings (Requested by user: Dark / Light / System)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              size: 20,
                              color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'App Appearance',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildThemeOption(
                                label: 'Light',
                                icon: Icons.light_mode_outlined,
                                isSelected: currentThemeMode == ThemeMode.light,
                                onTap: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(ThemeMode.light),
                                context: context,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeOption(
                                label: 'Dark',
                                icon: Icons.dark_mode_outlined,
                                isSelected: currentThemeMode == ThemeMode.dark,
                                onTap: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(ThemeMode.dark),
                                context: context,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildThemeOption(
                                label: 'System',
                                icon: Icons.brightness_auto_outlined,
                                isSelected: currentThemeMode == ThemeMode.system,
                                onTap: () => ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(ThemeMode.system),
                                context: context,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 14),

                // 4. Support Desk & Legal Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.support_agent_rounded,
                            color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                          ),
                          title: const Text('Support Desk'),
                          subtitle: Text(supportPhone),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_in_talk_rounded, size: 16, color: AppTheme.primaryColor),
                                SizedBox(width: 4),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () async {
                            final cleanPhone = supportPhone.replaceAll(RegExp(r'[^\d+]'), '');
                            final uri = Uri.parse('tel:$cleanPhone');
                            try {
                              final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                              if (!launched && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not open phone dialer for $supportPhone')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not initiate call: $e')),
                                );
                              }
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.privacy_tip_outlined,
                            color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                          ),
                          title: const Text('Privacy Policy'),
                          subtitle: const Text('Google Play & DPDP 2023 compliant data safety'),
                          trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                          onTap: () async {
                            const privacyUrl = 'https://riodent-prod.web.app/privacy.html';
                            final uri = Uri.parse(privacyUrl);
                            try {
                              final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                              if (!launched && context.mounted) {
                                _showPrivacyDialog(context, isDark);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                _showPrivacyDialog(context, isDark);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Sign Out and Delete Account Actions (Aligned within Card)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppTheme.cardBorderColor),
                          ),
                          onPressed: _handleSignOut,
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _handleDeleteAccount,
                          icon: const Icon(Icons.delete_forever_rounded, size: 20),
                          label: const Text('Delete RioDent Account', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String count,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppTheme.cardBorderColor,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedBg = isDark
        ? const Color(0xFF0369A1)
        : AppTheme.primaryLight;
    final selectedBorder = isDark
        ? const Color(0xFF38BDF8)
        : AppTheme.primaryColor;
    final selectedText = isDark
        ? Colors.white
        : AppTheme.primaryColor;

    final unselectedBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final unselectedBorder = isDark
        ? const Color(0xFF334155)
        : AppTheme.cardBorderColor;
    final unselectedText = isDark
        ? const Color(0xFF94A3B8)
        : AppTheme.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? selectedText : unselectedText,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? selectedText : unselectedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('RioDent Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RioDent connects licensed dental clinics in Hyderabad with verified dental equipment technicians.\n\n'
                '• Strict Data Minimization: We only collect doctor name, clinic name, mobile number, and clinic address required to dispatch a technician.\n'
                '• No Patient Data: We never collect, process, or store patient health records or medical charts.\n'
                '• Zero Data Selling: We never sell or monetize clinic data.\n'
                '• DPDP Act 2023 Compliant with Grievance Redressal and in-app account erasure.\n\n'
                'Official production policy URL:',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://riodent-prod.web.app/privacy.html'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text(
                  'https://riodent-prod.web.app/privacy.html',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0284C7),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open in Browser'),
            onPressed: () {
              Navigator.of(ctx).pop();
              launchUrl(
                Uri.parse('https://riodent-prod.web.app/privacy.html'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}




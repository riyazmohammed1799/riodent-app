import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/request_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

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
      _clinicController = TextEditingController(text: user?.clinicName ?? '');
      _phoneController = TextEditingController(text: user?.phone ?? '');
      _addressController = TextEditingController(text: user?.clinicAddress ?? '');
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
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

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
        await ref.read(userRepositoryProvider).deleteUserAccount(user.uid);
        await ref.read(authRepositoryProvider).deleteAccount();
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account deletion requires recent sign-in. Please sign in again and retry: $e',
            ),
          ),
        );
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
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Account Signed Out or Deleted',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You are no longer signed in to RioDent.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Go to Sign In'),
                    ),
                  ],
                ),
              ),
            );
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
                                    (user.clinicName != null && user.clinicName!.isNotEmpty)
                                        ? user.clinicName!
                                        : 'Dental Clinic',
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
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Mobile *',
                                    prefixIcon: Icon(Icons.phone_outlined),
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
                          trailing: const Icon(Icons.phone_in_talk_rounded, size: 18),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.privacy_tip_outlined,
                            color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                          ),
                          title: const Text('Privacy Policy'),
                          subtitle: const Text('Play Store compliant data safety'),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Privacy Policy'),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    'RioDent connects licensed dental clinics with certified dental equipment technicians. '
                                    'We only collect information required for booking, equipment diagnostics, and technician dispatch. '
                                    'We do not sell clinic or patient data to third parties. For full policy documentation, visit '
                                    'https://equip-services-dev.web.app/privacy.',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 5. Sign Out and Delete Account Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _handleSignOut,
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                        ),
                        onPressed: _handleDeleteAccount,
                        icon: const Icon(Icons.delete_forever_rounded, size: 20),
                        label: const Text('Delete RioDent Account'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
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
}




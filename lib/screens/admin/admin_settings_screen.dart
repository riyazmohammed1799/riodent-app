import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/booking_config_model.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';

/// Screen where the admin manages equipment categories and system policies.
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _newIssueTypeController = TextEditingController();
  List<String> _issueTypes = [];
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _newIssueTypeController.dispose();
    super.dispose();
  }

  void _initFields(BookingConfigModel config) {
    if (_isInitialized) return;
    _issueTypes = List<String>.from(config.issueTypes);
    _isInitialized = true;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final repo = ref.read(settingsRepositoryProvider);

    final currentConfig = ref.read(bookingConfigProvider).value ??
        BookingConfigModel.defaultConfig();

    final updated = BookingConfigModel(
      listedFee: 0.0,
      payableFee: 0.0,
      currency: 'INR',
      offerEnabled: false,
      offerLabel: '100% Free Service',
      maxPhotos: currentConfig.maxPhotos,
      maxPhotoSizeMB: currentConfig.maxPhotoSizeMB,
      maxVideoSizeMB: currentConfig.maxVideoSizeMB,
      maxVideoDurationSec: currentConfig.maxVideoDurationSec,
      issueTypes: _issueTypes,
      updatedAt: DateTime.now(),
    );

    try {
      await repo.updateBookingConfig(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved to Firebase')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addIssueType() {
    final text = _newIssueTypeController.text.trim();
    if (text.isNotEmpty && !_issueTypes.contains(text)) {
      setState(() {
        _issueTypes.add(text);
        _newIssueTypeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(bookingConfigProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('System Configuration'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) {
          _initFields(config);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Free Model Policy Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppTheme.successColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'App Service Model: 100% Free',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RioDent is a complimentary service platform. Clinics are never charged fees for technician dispatch, diagnosis, or booking requests.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: const Text(
                          'Charge Policy: ₹0 across all categories',
                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Issue Types Configuration
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Equipment / Problem Categories', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Doctors will see these categories when booking assistance.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _newIssueTypeController,
                                decoration: const InputDecoration(
                                  hintText: 'Add new category (e.g. Ultrasonic Scaler)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _addIssueType,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _issueTypes.map((type) {
                            return Chip(
                              label: Text(type),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() => _issueTypes.remove(type));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Categories to Firebase'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

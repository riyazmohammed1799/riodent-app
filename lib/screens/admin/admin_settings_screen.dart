import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_config_model.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';

/// Screen where the admin edits dynamic business configurations (fees, offers, equipment types).
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _listedFeeController;
  late TextEditingController _payableFeeController;
  late TextEditingController _offerLabelController;
  late TextEditingController _newIssueTypeController;

  bool _offerEnabled = true;
  List<String> _issueTypes = [];
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _listedFeeController = TextEditingController();
    _payableFeeController = TextEditingController();
    _offerLabelController = TextEditingController();
    _newIssueTypeController = TextEditingController();
  }

  @override
  void dispose() {
    _listedFeeController.dispose();
    _payableFeeController.dispose();
    _offerLabelController.dispose();
    _newIssueTypeController.dispose();
    super.dispose();
  }

  void _initFields(BookingConfigModel config) {
    if (_isInitialized) return;
    _listedFeeController.text = config.listedFee.toInt().toString();
    _payableFeeController.text = config.payableFee.toInt().toString();
    _offerLabelController.text = config.offerLabel;
    _offerEnabled = config.offerEnabled;
    _issueTypes = List<String>.from(config.issueTypes);
    _isInitialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = ref.read(settingsRepositoryProvider);

    final currentConfig = ref.read(bookingConfigProvider).value ??
        BookingConfigModel.defaultConfig();

    final updated = BookingConfigModel(
      listedFee: double.tryParse(_listedFeeController.text) ?? currentConfig.listedFee,
      payableFee: double.tryParse(_payableFeeController.text) ?? currentConfig.payableFee,
      currency: currentConfig.currency,
      offerEnabled: _offerEnabled,
      offerLabel: _offerLabelController.text.trim(),
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
        const SnackBar(content: Text('Settings updated successfully')),
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
      appBar: AppBar(
        title: const Text('Booking Configuration'),
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) {
          _initFields(config);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fee Configuration Card
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visit Pricing (INR)', style: theme.textTheme.titleMedium),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Standard Listed Fee (₹)', style: theme.textTheme.labelMedium),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _listedFeeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(hintText: '99'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Actual Payable Fee (₹)', style: theme.textTheme.labelMedium),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _payableFeeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(hintText: '0'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Promotional Offer Active'),
                            subtitle: const Text('Display promotional discount banner to dentists'),
                            value: _offerEnabled,
                            onChanged: (val) => setState(() => _offerEnabled = val),
                          ),
                          if (_offerEnabled) ...[
                            const SizedBox(height: 8),
                            Text('Offer Label Text', style: theme.textTheme.labelMedium),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _offerLabelController,
                              decoration: const InputDecoration(hintText: 'Limited Launch Offer'),
                            ),
                          ],
                        ],
                      ),
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
                          Text('Equipment / Issue Categories', style: theme.textTheme.titleMedium),
                          const Divider(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _newIssueTypeController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add new category (e.g. Suction)',
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

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Configuration to Firebase'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

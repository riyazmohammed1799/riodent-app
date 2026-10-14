import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/booking_config_model.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';

/// Screen where the admin manages equipment categories, slots, pincodes, cancel reasons,
/// support contact, and system policies.
/// Implements Section 3.8:
/// - Categories (add, rename, activate/deactivate; no hard delete)
/// - Slots
/// - Max days ahead
/// - Serviceable pincode prefixes
/// - Cancel reasons lists
/// - Support phone
/// - Max open requests per doctor
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _newCategoryController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _pincodesController = TextEditingController();
  final _maxDaysController = TextEditingController();
  final _maxOpenRequestsController = TextEditingController();

  List<IssueTypeItem> _categories = [];
  List<String> _doctorCancelReasons = [];
  List<String> _adminCancelReasons = [];

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _newCategoryController.dispose();
    _supportPhoneController.dispose();
    _pincodesController.dispose();
    _maxDaysController.dispose();
    _maxOpenRequestsController.dispose();
    super.dispose();
  }

  void _initFields(BookingConfigModel config) {
    if (_isInitialized) return;
    _categories = List<IssueTypeItem>.from(config.issueTypes);
    _supportPhoneController.text = config.supportPhone;
    _pincodesController.text = config.serviceablePincodePrefixes.join(', ');
    _maxDaysController.text = config.maxDaysAhead.toString();
    _maxOpenRequestsController.text = config.maxOpenRequests.toString();
    _doctorCancelReasons = List<String>.from(config.doctorCancelReasons);
    _adminCancelReasons = List<String>.from(config.adminCancelReasons);
    _isInitialized = true;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final repo = ref.read(settingsRepositoryProvider);
    final currentConfig = ref.read(bookingConfigProvider).value ?? BookingConfigModel.defaultConfig();

    final prefixes = _pincodesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final maxDays = int.tryParse(_maxDaysController.text.trim()) ?? currentConfig.maxDaysAhead;
    final maxOpen = int.tryParse(_maxOpenRequestsController.text.trim()) ?? currentConfig.maxOpenRequests;

    final updated = BookingConfigModel(
      issueTypes: _categories,
      slots: currentConfig.slots,
      maxDaysAhead: maxDays,
      minLeadMinutes: currentConfig.minLeadMinutes,
      serviceablePincodePrefixes: prefixes.isNotEmpty ? prefixes : currentConfig.serviceablePincodePrefixes,
      doctorCancelReasons: _doctorCancelReasons,
      adminCancelReasons: _adminCancelReasons,
      supportPhone: _supportPhoneController.text.trim().isNotEmpty ? _supportPhoneController.text.trim() : currentConfig.supportPhone,
      maxOpenRequests: maxOpen,
      updatedAt: DateTime.now(),
    );

    try {
      await repo.updateBookingConfig(updated);
      ref.invalidate(bookingConfigProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successColor,
          content: Text('Settings saved to Firebase Firestore'),
        ),
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

  void _addCategory() {
    final label = _newCategoryController.text.trim();
    if (label.isEmpty) return;
    final code = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    if (_categories.any((c) => c.code == code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category with this code already exists.')),
      );
      return;
    }

    setState(() {
      _categories.add(IssueTypeItem(code: code, label: label, active: true));
      _newCategoryController.clear();
    });
  }

  void _renameCategory(int index) async {
    final cat = _categories[index];
    final renameController = TextEditingController(text: cat.label);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(labelText: 'Category Label'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(renameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _categories[index] = IssueTypeItem(
          code: cat.code,
          label: newName,
          active: cat.active,
        );
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
                // Equipment Categories Section
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
                      Text('Equipment Categories (Active / Inactive)', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Categories can be added, renamed, or deactivated. Deactivated items are hidden from doctors but preserve past booking history.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const Divider(height: 20),

                      // Add Category Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newCategoryController,
                              decoration: const InputDecoration(
                                hintText: 'New category name (e.g. Dental Laser)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _addCategory,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Category List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _categories.length,
                        separatorBuilder: (_, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _categories[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: item.active ? null : TextDecoration.lineThrough,
                                color: item.active ? AppTheme.textPrimary : AppTheme.textHint,
                              ),
                            ),
                            subtitle: Text('Code: ${item.code}', style: const TextStyle(fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Rename Label',
                                  onPressed: () => _renameCategory(index),
                                ),
                                Switch(
                                  value: item.active,
                                  onChanged: (val) {
                                    setState(() {
                                      _categories[index] = IssueTypeItem(
                                        code: item.code,
                                        label: item.label,
                                        active: val,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Operational Limits & Service Area
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
                      Text('Service Area & Rules', style: theme.textTheme.titleMedium),
                      const Divider(height: 20),

                      TextFormField(
                        controller: _supportPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Support Desk Phone *',
                          hintText: '+91 98765 43210',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _pincodesController,
                        decoration: const InputDecoration(
                          labelText: 'Serviceable Pincode Prefixes (comma separated) *',
                          hintText: '500, 501, 502',
                          prefixIcon: Icon(Icons.pin_drop_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _maxDaysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Days Ahead',
                                hintText: '7',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxOpenRequestsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Max Open Req / Doctor',
                                hintText: '3',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _isSaving ? null : _handleSave,
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Configuration Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

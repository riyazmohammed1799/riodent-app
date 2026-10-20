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
  String _newCategoryImageAsset = 'assets/images/equipment/other.jpg';

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

  Future<String?> _pickEquipmentImage(BuildContext context, String currentAsset) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Equipment Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: IssueTypeItem.availableEquipmentImages.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, idx) {
                final item = IssueTypeItem.availableEquipmentImages[idx];
                final path = item['path']!;
                final name = item['name']!;
                final isSelected = path == currentAsset;

                return InkWell(
                  onTap: () => Navigator.of(ctx).pop(path),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE0F2FE) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0284C7) : AppTheme.cardBorderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                path,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.build_rounded, size: 24, color: AppTheme.primaryColor),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0284C7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? const Color(0xFF0284C7) : AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
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
      _categories.add(IssueTypeItem(
        code: code,
        label: label,
        active: true,
        imageAsset: _newCategoryImageAsset,
      ));
      _newCategoryController.clear();
      _newCategoryImageAsset = 'assets/images/equipment/other.jpg';
    });
  }

  void _editCategory(int index) async {
    final cat = _categories[index];
    final renameController = TextEditingController(text: cat.label);
    String selectedImage = cat.effectiveImageAsset;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Equipment Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: renameController,
                      decoration: const InputDecoration(labelText: 'Category Label'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Equipment Photo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await _pickEquipmentImage(context, selectedImage);
                        if (picked != null) {
                          setDialogState(() => selectedImage = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                selectedImage,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.build_rounded, size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tap to Change Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('Select from equipment catalog', style: TextStyle(fontSize: 11, color: AppTheme.textHint)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.blueGreyAccent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final label = renameController.text.trim();
                    if (label.isEmpty) return;
                    Navigator.of(ctx).pop({'label': label, 'image': selectedImage});
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _categories[index] = IssueTypeItem(
          code: cat.code,
          label: result['label']!,
          active: cat.active,
          imageAsset: result['image']!,
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
                          // Equipment Image Selector for New Category
                          InkWell(
                            onTap: () async {
                              final picked = await _pickEquipmentImage(context, _newCategoryImageAsset);
                              if (picked != null) {
                                setState(() => _newCategoryImageAsset = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Tooltip(
                              message: 'Choose Equipment Image',
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      _newCategoryImageAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.build_rounded, size: 20),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        color: Colors.black54,
                                        child: const Icon(Icons.photo_camera, size: 10, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                item.effectiveImageAsset,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.build_rounded,
                                  size: 24,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
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
                                  tooltip: 'Edit Category & Image',
                                  onPressed: () => _editCategory(index),
                                ),
                                Switch(
                                  value: item.active,
                                  onChanged: (val) {
                                    setState(() {
                                      _categories[index] = IssueTypeItem(
                                        code: item.code,
                                        label: item.label,
                                        active: val,
                                        imageAsset: item.imageAsset,
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

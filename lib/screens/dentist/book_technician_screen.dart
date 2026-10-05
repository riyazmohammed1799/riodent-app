import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Screen where dentists specify the equipment issue and details for technician dispatch.
class BookTechnicianScreen extends ConsumerStatefulWidget {
  const BookTechnicianScreen({super.key});

  @override
  ConsumerState<BookTechnicianScreen> createState() => _BookTechnicianScreenState();
}

class _BookTechnicianScreenState extends ConsumerState<BookTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedIssueType;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _proceedToReview() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIssueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an equipment category')),
      );
      return;
    }

    final dentist = ref.read(currentUserProfileProvider).value;
    if (dentist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile not loaded. Please complete your profile first.')),
      );
      return;
    }

    final config = ref.read(bookingConfigProvider).value;

    context.push('/dentist/review', extra: {
      'issueType': _selectedIssueType,
      'issueDescription': _descriptionController.text.trim(),
      'dentist': dentist,
      'config': config,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(bookingConfigProvider);
    final dentist = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Book Dental Technician'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clinic summary card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dentist?.clinicName ?? 'Registered Clinic',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (dentist?.clinicAddress != null && dentist!.clinicAddress!.isNotEmpty)
                                  ? dentist.clinicAddress!
                                  : 'Bengaluru / Hyderabad Verified Location',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: const Text(
                                'Complimentary Service • ₹0 Visit Fee',
                                style: TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Equipment / Issue Category',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                configAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => const Text('Error loading options'),
                  data: (config) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedIssueType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select affected equipment',
                        prefixIcon: Icon(Icons.build_circle_outlined, size: 20),
                      ),
                      items: config.issueTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedIssueType = val);
                      },
                      validator: (val) => val == null ? 'Please select an equipment category' : null,
                    );
                  },
                ),

                const SizedBox(height: 20),
                Text(
                  'Issue Details & Symptoms',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please describe what is happening (e.g. error code, water leakage, motor vibrating, no pressure).',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dental chair hydraulic system is not tilting up. Started this morning...',
                  ),
                  validator: Validators.description,
                ),

                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _proceedToReview,
                  child: const Text('Review Booking Details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

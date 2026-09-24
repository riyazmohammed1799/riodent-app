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
        const SnackBar(content: Text('Please select an equipment or issue type')),
      );
      return;
    }

    final dentist = ref.read(currentUserProfileProvider).value;
    if (dentist == null) return;

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
      appBar: AppBar(
        title: const Text('Book Technician'),
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
                Card(
                  margin: EdgeInsets.zero,
                  color: AppTheme.backgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dentist?.clinicName ?? 'Clinic Location',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dentist?.clinicAddress ?? 'No address registered',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Select Issue or Equipment',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                configAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Text('Error loading options'),
                  data: (config) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedIssueType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Choose equipment problem',
                        prefixIcon: Icon(Icons.build_circle_outlined),
                      ),
                      items: config.issueTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedIssueType = val);
                      },
                      validator: (val) => val == null ? 'Please select an equipment issue' : null,
                    );
                  },
                ),

                const SizedBox(height: 24),
                Text(
                  'Describe the Issue',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'What symptoms or errors are you experiencing? (e.g. noise, leak, power failure)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Enter detailed equipment symptoms, make/model, urgency...',
                  ),
                  validator: Validators.description,
                ),

                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _proceedToReview,
                  child: const Text('Review & Confirm Booking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

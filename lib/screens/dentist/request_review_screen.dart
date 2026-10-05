import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/technician_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/request_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Screen where dentists review booking details and confirm technician dispatch.
class RequestReviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> requestData;

  const RequestReviewScreen({
    super.key,
    required this.requestData,
  });

  @override
  ConsumerState<RequestReviewScreen> createState() => _RequestReviewScreenState();
}

class _RequestReviewScreenState extends ConsumerState<RequestReviewScreen> {
  bool _isSubmitting = false;

  Future<void> _handleSubmitRequest() async {
    setState(() => _isSubmitting = true);

    final dentist = widget.requestData['dentist'] as UserModel;
    final issueType = widget.requestData['issueType'] as String;
    final issueDescription = widget.requestData['issueDescription'] as String;

    final requestRepo = ref.read(requestRepositoryProvider);
    final now = DateTime.now();

    final newRequest = TechnicianRequestModel(
      id: '',
      dentistId: dentist.uid,
      dentistName: dentist.displayName,
      dentistPhone: dentist.phone,
      clinicName: dentist.clinicName ?? '',
      clinicAddress: dentist.clinicAddress ?? '',
      clinicLatitude: dentist.clinicLatitude ?? 0.0,
      clinicLongitude: dentist.clinicLongitude ?? 0.0,
      issueType: issueType,
      issueDescription: issueDescription,
      photos: const [],
      video: null,
      status: AppConstants.statusNew,
      listedFee: 0.0,
      payableFee: 0.0,
      currency: 'INR',
      offerLabel: '100% Free Service',
      createdAt: now,
      updatedAt: now,
    );

    try {
      final docId = await requestRepo.createRequest(newRequest);
      if (!mounted) return;
      context.go('/dentist/submitted', extra: docId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dentist = widget.requestData['dentist'] as UserModel;
    final issueType = widget.requestData['issueType'] as String;
    final issueDescription = widget.requestData['issueDescription'] as String;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Review & Confirm'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clinic Destination Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.apartment_rounded, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('Clinic Location', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        dentist.clinicName?.isNotEmpty == true ? dentist.clinicName! : 'Clinic Destination',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dentist.clinicAddress?.isNotEmpty == true ? dentist.clinicAddress! : 'Address on file',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Contact: ${dentist.phone.isNotEmpty ? dentist.phone : (dentist.email ?? 'On file')}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Equipment Issue Details
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.build_circle_rounded, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('Issue Details', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const Divider(height: 20),
                      Text('Equipment Category', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(issueType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Text('Description & Symptoms', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(issueDescription, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Free Service Policy Guarantee Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: AppTheme.successColor),
                          const SizedBox(width: 8),
                          Text(
                            'RioDent Free Service Guarantee',
                            style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.successColor),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Technician Dispatch Fee'),
                          Text(
                            '₹0 (FREE)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Clinic Inspection Charges'),
                          Text(
                            '₹0 (COMPLIMENTARY)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Payable', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            '₹0',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm & Book Technician'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

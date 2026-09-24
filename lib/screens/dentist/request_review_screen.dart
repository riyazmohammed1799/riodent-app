import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/booking_config_model.dart';
import '../../models/technician_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/request_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Screen where dentists review all booking details, visit fees, and submit the request.
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
    final config = widget.requestData['config'] as BookingConfigModel? ??
        BookingConfigModel.defaultConfig();
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
      listedFee: config.listedFee,
      payableFee: config.payableFee,
      currency: config.currency,
      offerLabel: config.offerEnabled ? config.offerLabel : null,
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
    final config = widget.requestData['config'] as BookingConfigModel? ??
        BookingConfigModel.defaultConfig();
    final issueType = widget.requestData['issueType'] as String;
    final issueDescription = widget.requestData['issueDescription'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Booking'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clinic Destination
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
                      const Divider(height: 24),
                      Text(dentist.clinicName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(dentist.clinicAddress ?? '', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Contact: ${dentist.phone}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Equipment Issue
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.build_rounded, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('Issue Details', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const Divider(height: 24),
                      Text('Equipment / Category', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(issueType, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text('Description', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(issueDescription, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Visit Fee Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('Visit Fee Breakdown', style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Technician Visit Fee'),
                          Text(
                            '₹${config.listedFee.toInt()}',
                            style: const TextStyle(decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ),
                      if (config.offerEnabled) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              config.offerLabel,
                              style: const TextStyle(color: AppTheme.successColor),
                            ),
                            Text(
                              '- ₹${(config.listedFee - config.payableFee).toInt()}',
                              style: const TextStyle(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payable Now', style: theme.textTheme.titleMedium),
                          Text(
                            '₹${config.payableFee.toInt()}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/technician_request_model.dart';
import '../../providers/request_providers.dart';
import '../../providers/user_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Screen where dentists review booking details and confirm technician dispatch.
/// Implements Section 3.3:
/// - Full review of Doctor, Clinic, Mobile, Full Address, Category, Description, Slot
/// - Status: 'Technician will be assigned by RioDent'
/// - Clear fee notice: 'RioDent is free to use. Any technician charges are paid directly to the technician after the visit.'
/// - Idempotent pre-generated doc ID and submit button disabling
/// - Saves clinic name, mobile, and address to profile for future auto-prefill
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
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final requestRepo = ref.read(requestRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    final dentistId = widget.requestData['dentistId'] as String? ?? '';
    final dentistName = widget.requestData['dentistName'] as String? ?? '';
    final clinicName = widget.requestData['clinicName'] as String? ?? '';
    final mobile = widget.requestData['mobile'] as String? ?? '';

    final addressLine = widget.requestData['addressLine'] as String? ?? '';
    final landmark = widget.requestData['landmark'] as String?;
    final area = widget.requestData['area'] as String?;
    final city = widget.requestData['city'] as String? ?? 'Hyderabad';
    final state = widget.requestData['state'] as String? ?? 'Telangana';
    final pincode = widget.requestData['pincode'] as String? ?? '';
    final lat = (widget.requestData['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (widget.requestData['lng'] as num?)?.toDouble() ?? 0.0;

    final issueCode = widget.requestData['issueCode'] as String? ?? '';
    final issueLabel = widget.requestData['issueLabel'] as String? ?? '';
    final issueDescription = widget.requestData['issueDescription'] as String? ?? '';

    final slotDate = widget.requestData['slotDate'] as String? ?? '';
    final slotKey = widget.requestData['slotKey'] as String? ?? '';
    final slotLabel = widget.requestData['slotLabel'] as String? ?? '';
    final slotStart = widget.requestData['slotStart'] as DateTime? ?? DateTime.now();

    // Pre-generate unique document ID
    final preGeneratedId = requestRepo.generateNewRequestId();
    final shortSuffix = (100000 + Random().nextInt(900000)).toString();
    final ticketNumber = 'REQ-$shortSuffix';
    final now = DateTime.now();

    final structuredAddress = RequestAddress(
      line: addressLine,
      landmark: landmark,
      area: area,
      city: city,
      state: state,
      pincode: pincode,
      lat: lat,
      lng: lng,
    );

    final request = TechnicianRequestModel(
      id: preGeneratedId,
      ticketNumber: ticketNumber,
      dentistId: dentistId,
      dentistName: dentistName,
      clinicName: clinicName,
      mobile: mobile,
      address: structuredAddress,
      issueCode: issueCode,
      issueLabel: issueLabel,
      issueDescription: issueDescription,
      slotDate: slotDate,
      slotKey: slotKey,
      slotStart: slotStart,
      status: AppConstants.statusNew,
      createdAt: now,
      updatedAt: now,
    );

    try {
      // 1. Submit ticket with initial event
      await requestRepo.createRequest(request);

      // 2. Prefill profile with latest booking details for future convenience
      if (dentistId.isNotEmpty) {
        try {
          await userRepo.updateDentistProfile(
            uid: dentistId,
            displayName: dentistName,
            clinicName: clinicName,
            clinicAddress: structuredAddress.fullAddress,
            phone: mobile,
            clinicLatitude: lat > 0 ? lat : null,
            clinicLongitude: lng > 0 ? lng : null,
          );
        } catch (_) {
          // Non-critical profile caching error
        }
      }

      if (!mounted) return;
      context.go('/dentist/submitted', extra: {
        'ticketNumber': ticketNumber,
        'mobile': mobile,
        'slot': slotLabel,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dentistName = widget.requestData['dentistName'] as String? ?? '';
    final clinicName = widget.requestData['clinicName'] as String? ?? '';
    final mobile = widget.requestData['mobile'] as String? ?? '';
    final addressLine = widget.requestData['addressLine'] as String? ?? '';
    final landmark = widget.requestData['landmark'] as String?;
    final area = widget.requestData['area'] as String?;
    final pincode = widget.requestData['pincode'] as String? ?? '';
    final issueLabel = widget.requestData['issueLabel'] as String? ?? '';
    final issueDescription = widget.requestData['issueDescription'] as String? ?? '';
    final city = widget.requestData['city'] as String? ?? 'Hyderabad';
    final state = widget.requestData['state'] as String? ?? 'Telangana';
    final slotDisplayDate = widget.requestData['slotDisplayDate'] as String? ?? '';

    final fullAddressText = [
      addressLine,
      if (landmark != null && landmark.isNotEmpty) 'Near $landmark',
      if (area != null && area.isNotEmpty) area,
      city,
      if (state.isNotEmpty && state.toLowerCase() != city.toLowerCase()) state,
      if (pincode.isNotEmpty) pincode,
    ].where((p) => p.trim().isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Review Booking'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Free Policy Notice Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'RioDent is free to use. Any technician charges are paid directly to the technician after the visit.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 1. Clinic & Doctor Card
              _buildSectionCard(
                title: 'Clinic & Contact',
                icon: Icons.local_hospital_rounded,
                children: [
                  _buildDataRow('Doctor Name', dentistName),
                  _buildDataRow('Clinic Name', clinicName),
                  _buildDataRow('Contact Mobile', mobile),
                  _buildDataRow('Full Address', fullAddressText),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Equipment & Problem Card
              _buildSectionCard(
                title: 'Equipment & Breakdown',
                icon: Icons.build_rounded,
                children: [
                  _buildDataRow('Category', issueLabel),
                  _buildDataRow('Description', issueDescription),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Visit Schedule & Commitment Card
              _buildSectionCard(
                title: 'Visit Schedule & Commitment',
                icon: Icons.calendar_today_rounded,
                children: [
                  _buildDataRow('Preferred Date', slotDisplayDate),
                  _buildDataRow('Service Commitment', 'We will contact you within 24 hours to coordinate the technician visit.'),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Initial Status',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Text(
                            'Pending (Technician will be assigned)',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Confirm Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting ? null : _handleSubmitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Confirm & Request Technician',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

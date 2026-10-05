import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/request_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Screen showing live real-time status and details of a single request for a dentist.
class RequestDetailsScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestAsync = ref.watch(requestDetailProvider(requestId));
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Request Status'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (req) {
          if (req == null) {
            return const Center(child: Text('Request not found'));
          }

          final statusColor = AppTheme.getStatusColor(req.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Banner Card
                Card(
                  margin: EdgeInsets.zero,
                  color: statusColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: statusColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTheme.getStatusLabel(req.status),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getStatusDescription(req.status),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Assigned Technician info if present
                if (req.assignedTechnicianName != null) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text('Assigned Technician', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            req.assignedTechnicianName!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Technician dispatched to your clinic.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                            Text('Equipment & Problem', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Equipment', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 2),
                        Text(req.issueType, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('Description', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 2),
                        Text(req.issueDescription, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Clinic & Booking Metadata
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
                            Text('Clinic Information', style: theme.textTheme.titleMedium),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(req.clinicName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(req.clinicAddress, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Text('Submitted At', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 2),
                        Text(dateFormat.format(req.createdAt), style: theme.textTheme.bodySmall),
                        const SizedBox(height: 12),
                        Text('Visit Fee', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 2),
                        const Text(
                          '₹0 (100% Free Service)',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case AppConstants.statusNew:
        return 'Request received. Awaiting technician assignment.';
      case AppConstants.statusAssigned:
        return 'Technician has been assigned and notified.';
      case AppConstants.statusInProgress:
        return 'Technician is actively servicing equipment at your clinic.';
      case AppConstants.statusCompleted:
        return 'Service completed. Equipment operational.';
      case AppConstants.statusCancelled:
        return 'This service request was cancelled.';
      default:
        return '';
    }
  }
}

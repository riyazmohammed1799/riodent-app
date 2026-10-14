import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking_config_model.dart';
import '../../models/technician_request_model.dart';
import '../../providers/request_providers.dart';
import '../../providers/settings_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'edit_request_dialog.dart';

/// Screen showing live status and details of a single request for a doctor.
class RequestDetailsScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  Future<void> _handleDoctorEdit(
    BuildContext context,
    WidgetRef ref,
    TechnicianRequestModel req,
    BookingConfigModel config,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditRequestDialog(request: req, config: config),
    );

    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successColor,
          content: Text('Service request updated successfully.'),
        ),
      );
    }
  }

  Future<void> _handleDoctorCancel(
    BuildContext context,
    WidgetRef ref,
    TechnicianRequestModel req,
    BookingConfigModel config,
  ) async {
    final reasons = config.doctorCancelReasons;
    String selectedReason = reasons.isNotEmpty ? reasons.first : 'No longer needed';
    final otherController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
              SizedBox(width: 8),
              Text('Cancel Service Request'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket ${req.displayTicketId} • ${req.issueLabel}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  const Text('Reason for Cancellation *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedReason = val);
                      }
                    },
                  ),
                  if (selectedReason == 'Other') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: otherController,
                      decoration: const InputDecoration(
                        labelText: 'Please explain reason *',
                        hintText: 'Enter reason for cancellation',
                      ),
                      validator: (val) => Validators.required(val, 'Reason'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Ticket Active'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Confirm Cancellation'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final reasonText = selectedReason == 'Other' ? otherController.text.trim() : selectedReason;
        await ref.read(requestRepositoryProvider).cancelRequest(
          requestId: req.id,
          cancelledBy: 'dentist',
          reasonCode: selectedReason.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
          reasonText: reasonText,
        );
        ref.invalidate(requestDetailProvider(req.id));
        ref.invalidate(dentistRequestsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.errorColor,
              content: Text('Service request cancelled.'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel request: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleDoctorComplete(
    BuildContext context,
    WidgetRef ref,
    TechnicianRequestModel req,
  ) async {
    final amountController = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    // Dialog 1: Prompt amount paid in whole rupees (0 to 100,000)
    final enteredAmount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text('Mark as Completed'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Has the technician visited and attended to your ${req.issueLabel}?',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'How much did you pay the technician? (Rs) *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    hintText: '0 (enter 0 if complimentary or free visit)',
                  ),
                  validator: Validators.amountPaid,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter whole rupee amount from ₹0 to ₹1,00,000 paid directly to the technician.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                Navigator.of(ctx).pop(amt);
              }
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );

    if (enteredAmount == null) return;

    if (!context.mounted) return;
    // Dialog 2: Second confirmation per Section 3.5: "Confirm that you paid Rs X and close this ticket?"
    final confirmClose = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment & Close'),
        content: Text(
          'Confirm that you paid ₹${enteredAmount.toInt()} and close this ticket?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Close Ticket'),
          ),
        ],
      ),
    );

    if (confirmClose == true) {
      try {
        await ref.read(requestRepositoryProvider).completeRequest(
          requestId: req.id,
          amountPaid: enteredAmount,
          completedBy: 'dentist',
        );
        ref.invalidate(requestDetailProvider(req.id));
        ref.invalidate(dentistRequestsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.successColor,
              content: Text('Ticket closed successfully. Recorded payment of ₹${enteredAmount.toInt()}.'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to close ticket: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestDetailProvider(requestId));
    final eventsAsync = ref.watch(requestEventsProvider(requestId));
    final config = ref.watch(bookingConfigProvider).value ?? BookingConfigModel.defaultConfig();
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ticket Details'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          if (requestAsync.value != null && (requestAsync.value!.isNew || requestAsync.value!.isAssigned))
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Edit Request Details',
              onPressed: () => _handleDoctorEdit(context, ref, requestAsync.value!, config),
            ),
        ],
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (req) {
          if (req == null) {
            return const Center(child: Text('Ticket not found'));
          }

          final statusColor = AppTheme.getStatusColor(req.status);
          final statusLabel = AppTheme.getStatusLabel(req.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Ticket ID & Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.displayTicketId,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Booked on ${dateFormat.format(req.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Assigned Technician Notification Card (if assigned)
                if (req.assignedTechnicianName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_pin_circle_rounded, color: AppTheme.successColor, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Technician ${req.assignedTechnicianName} will call or visit you during your slot.',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF14532D)),
                              ),
                              if (req.assignedTechnicianPhone != null && req.assignedTechnicianPhone!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Phone: ${req.assignedTechnicianPhone}',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Equipment & Issue Card
                _buildCard(
                  title: 'Equipment & Problem',
                  icon: Icons.build_rounded,
                  trailing: (req.isNew || req.isAssigned)
                      ? TextButton.icon(
                          onPressed: () => _handleDoctorEdit(context, ref, req, config),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      : null,
                  children: [
                    _buildRow('Category', req.issueLabel),
                    _buildRow('Description', req.issueDescription),
                    _buildRow('Preferred Slot', '${req.slotDate.isNotEmpty ? req.slotDate : DateFormat('yyyy-MM-dd').format(req.slotStart)} (${DateFormat('h:mm a').format(req.slotStart)})'),
                  ],
                ),

                const SizedBox(height: 14),

                // Clinic & Address Card
                _buildCard(
                  title: 'Clinic & Contact',
                  icon: Icons.location_on_rounded,
                  children: [
                    _buildRow('Clinic Name', req.clinicName),
                    _buildRow('Doctor Name', req.dentistName),
                    _buildRow('Mobile', req.mobile),
                    _buildRow('Address', req.address.fullAddress),
                  ],
                ),

                const SizedBox(height: 14),

                // Status Timeline Card (from events subcollection)
                _buildCard(
                  title: 'Status Timeline',
                  icon: Icons.timeline_rounded,
                  children: [
                    eventsAsync.when(
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                      error: (err, _) => Text('Error: $err'),
                      data: (events) {
                        if (events.isEmpty) {
                          return const Text('Ticket created and waiting for dispatch.');
                        }
                        return Column(
                          children: events.map((event) {
                            final eColor = AppTheme.getStatusColor(event.status);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 4, right: 10),
                                    decoration: BoxDecoration(color: eColor, shape: BoxShape.circle),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              AppTheme.getStatusLabel(event.status),
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: eColor),
                                            ),
                                            Text(
                                              DateFormat('MMM dd, hh:mm a').format(event.at),
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                                            ),
                                          ],
                                        ),
                                        if (event.note != null && event.note!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(event.note!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),

                // Completion Info (if completed)
                if (req.isCompleted) ...[
                  const SizedBox(height: 14),
                  _buildCard(
                    title: 'Closure Summary',
                    icon: Icons.check_circle_rounded,
                    children: [
                      _buildRow('Amount Paid to Technician', '₹${req.amountPaid?.toInt() ?? 0}'),
                      if (req.completedAt != null) _buildRow('Completed On', dateFormat.format(req.completedAt!)),
                      _buildRow('Closed By', req.completedBy == 'admin' ? 'RioDent Operations' : 'Clinic Doctor'),
                    ],
                  ),
                ],

                // Cancellation Info (if cancelled)
                if (req.isCancelled) ...[
                  const SizedBox(height: 14),
                  _buildCard(
                    title: 'Cancellation Details',
                    icon: Icons.cancel_rounded,
                    children: [
                      _buildRow('Reason', req.reasonText ?? 'Cancelled'),
                      if (req.cancelledAt != null) _buildRow('Cancelled On', dateFormat.format(req.cancelledAt!)),
                      _buildRow('Cancelled By', req.cancelledBy == 'admin' ? 'RioDent Operations' : 'Clinic Doctor'),
                      const SizedBox(height: 12),
                      // Book Again Button per Section 3.6
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          context.push('/dentist/book', extra: {'category': req.issueCode});
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Book Again (Prefilled)'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons for Doctor
                if (TechnicianRequestModel.canDoctorComplete(req.status)) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _handleDoctorComplete(context, ref, req),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(height: 10),
                ],

                // Doctor Edit Button (if still editable)
                if (req.isNew || req.isAssigned) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _handleDoctorEdit(context, ref, req, config),
                    icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                    label: const Text('Edit Issue / Change Time Slot', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                ],

                if (TechnicianRequestModel.canDoctorCancel(req.status)) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _handleDoctorCancel(context, ref, req, config),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else if (req.isInProgress) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppTheme.warningColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Technician is currently attending. To cancel this service, please contact support: ${config.supportPhone}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
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
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark),
                ),
              ),
              ?trailing,
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

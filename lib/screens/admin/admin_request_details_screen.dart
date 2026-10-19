import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_config_model.dart';
import '../../models/technician_model.dart';
import '../../models/technician_request_model.dart';
import '../../providers/request_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/technician_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

/// Screen for administrative review of a single request, technician assignment,
/// status transitions, internal notes, and Google Maps location.
class AdminRequestDetailsScreen extends ConsumerStatefulWidget {
  final String requestId;

  const AdminRequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<AdminRequestDetailsScreen> createState() => _AdminRequestDetailsScreenState();
}

class _AdminRequestDetailsScreenState extends ConsumerState<AdminRequestDetailsScreen> {

  Future<void> _handleAssignTechnician(TechnicianRequestModel req) async {
    // 1. Check Riverpod cached stream value
    List<TechnicianModel> activeTechs = ref.read(activeTechniciansProvider).value ?? [];

    // 2. Fallback to direct async fetch if stream is warming up
    if (activeTechs.isEmpty) {
      try {
        activeTechs = await ref.read(technicianRepositoryProvider).getActiveTechnicians();
      } catch (_) {}
    }

    // 3. If no technician exists in roster, prompt admin to quickly add one and assign directly
    if (activeTechs.isEmpty) {
      if (!mounted) return;
      final quickTech = await _showQuickAddTechnicianDialog(req);
      if (quickTech == null) return;
      activeTechs = [quickTech];
    }

    if (!mounted) return;
    TechnicianModel selectedTech = activeTechs.first;

    final confirmed = await showDialog<TechnicianModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Assign Technician'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ticket: ${req.displayTicketId} • ${req.issueLabel}'),
              const SizedBox(height: 14),
              const Text('Select Active Field Technician *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<TechnicianModel>(
                initialValue: selectedTech,
                isExpanded: true,
                items: activeTechs.map((t) {
                  final areaStr = t.area != null && t.area!.isNotEmpty ? ' (${t.area})' : '';
                  return DropdownMenuItem(
                    value: t,
                    child: Text('${t.name}$areaStr • ${t.phone}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedTech = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(selectedTech),
              child: const Text('Confirm Assignment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null) {
      try {
        await ref.read(requestRepositoryProvider).assignTechnician(
          requestId: req.id,
          technicianId: confirmed.id,
          technicianName: confirmed.name,
          technicianPhone: confirmed.phone,
        );
        ref.invalidate(requestDetailProvider(req.id));
        ref.invalidate(adminRequestsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.successColor,
              content: Text('Technician ${confirmed.name} assigned to ticket.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assignment failed: $e')),
          );
        }
      }
    }
  }

  /// Fallback dialog when no active technicians exist in the roster yet.
  Future<TechnicianModel?> _showQuickAddTechnicianDialog(TechnicianRequestModel req) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return await showDialog<TechnicianModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Technicians in Roster'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a technician below to immediately assign them to this ticket:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Technician Name *', hintText: 'e.g. Ramesh Kumar'),
                validator: (val) => Validators.required(val, 'Name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Phone Number (10 digits) *',
                  hintText: '9876543210',
                  counterText: '',
                ),
                validator: Validators.phoneNumber,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                await ref.read(technicianRepositoryProvider).addTechnician(
                  name: name,
                  phone: phone,
                  area: 'Hyderabad',
                  specialization: req.issueLabel,
                );
                ref.invalidate(techniciansProvider);
                ref.invalidate(activeTechniciansProvider);
                final techs = await ref.read(technicianRepositoryProvider).getActiveTechnicians();
                final created = techs.firstWhere((t) => t.phone == phone, orElse: () => techs.first);
                if (ctx.mounted) Navigator.of(ctx).pop(created);
              }
            },
            child: const Text('Add & Proceed'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCloseOnBehalf(TechnicianRequestModel req) async {
    final amountController = TextEditingController();
    amountController.addListener(() {
      final text = amountController.text;
      if (text.length > 1 && text.startsWith('0') && text[1] != '.') {
        final clean = text.replaceFirst(RegExp(r'^0+'), '');
        final finalText = clean.isEmpty ? '0' : clean;
        amountController.value = TextEditingValue(
          text: finalText,
          selection: TextSelection.collapsed(offset: finalText.length),
        );
      }
    });
    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close on Behalf of Doctor'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ticket: ${req.displayTicketId} • ${req.clinicName}'),
              const SizedBox(height: 14),
              const Text('Amount Paid to Technician (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: '₹ ', hintText: 'e.g. 1000 (0 if complimentary)'),
                validator: Validators.amountPaid,
              ),
              const SizedBox(height: 4),
              const Text('Enter 0 for complimentary visit or total repair charge collected.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final clean = amountController.text.trim().replaceFirst(RegExp(r'^0+(?=\d)'), '');
                final amt = double.tryParse(clean.isEmpty ? '0' : clean) ?? 0.0;
                Navigator.of(ctx).pop(amt);
              }
            },
            child: const Text('Close Ticket'),
          ),
        ],
      ),
    );

    if (amount != null) {
      try {
        await ref.read(requestRepositoryProvider).completeRequest(
          requestId: req.id,
          amountPaid: amount,
          completedBy: 'admin',
        );
        ref.invalidate(requestDetailProvider(req.id));
        ref.invalidate(adminRequestsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.successColor,
              content: Text('Ticket closed on behalf of doctor. Recorded ₹${amount.toInt()}.'),
            ),
          );
          context.go('/admin');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to close ticket: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleAdminCancel(TechnicianRequestModel req, BookingConfigModel config) async {
    final reasons = config.adminCancelReasons;
    String selectedReason = reasons.isNotEmpty ? reasons.first : 'Other';
    final otherController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Cancel / Deny Ticket'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ticket: ${req.displayTicketId} • ${req.clinicName}'),
                  const SizedBox(height: 14),
                  const Text('Reason *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    isExpanded: true,
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedReason = val);
                    },
                  ),
                  if (selectedReason == 'Other') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: otherController,
                      decoration: const InputDecoration(labelText: 'Explain Reason *'),
                      validator: (val) => Validators.required(val, 'Reason'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Confirm Cancel'),
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
          cancelledBy: 'admin',
          reasonCode: selectedReason.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
          reasonText: reasonText,
        );
        ref.invalidate(requestDetailProvider(req.id));
        ref.invalidate(adminRequestsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: AppTheme.errorColor, content: Text('Ticket cancelled.')),
          );
          context.go('/admin');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeTechniciansProvider);
    final reqAsync = ref.watch(requestDetailProvider(widget.requestId));
    final eventsAsync = ref.watch(requestEventsProvider(widget.requestId));
    final config = ref.watch(bookingConfigProvider).value ?? BookingConfigModel.defaultConfig();
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    debugPrint('*** AdminRequestDetailsScreen build: requestId=${widget.requestId}');
    debugPrint('*** reqAsync state: $reqAsync');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Ticket Review'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin');
            }
          },
        ),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/admin');
          }
        },
        child: reqAsync.when(
          loading: () {
            debugPrint('*** reqAsync is LOADING for ${widget.requestId}');
            return const Center(child: CircularProgressIndicator());
          },
          error: (err, stack) {
            debugPrint('*** reqAsync ERROR: $err\n$stack');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading ticket: $err', style: const TextStyle(color: AppTheme.errorColor)),
              ),
            );
          },
          data: (req) {
            debugPrint('*** reqAsync DATA: req=$req, id=${req?.id}, ticket=${req?.displayTicketId}');
            if (req == null) {
              return const Center(child: Text('Ticket not found'));
            }

            final statusColor = AppTheme.getStatusColor(req.status);
            final statusLabel = AppTheme.getStatusLabel(req.status, req.cancelledBy);
            final hasTechnician = req.assignedTechnicianId != null && req.assignedTechnicianId!.isNotEmpty;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Ticket ID & Status
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.displayTicketId,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${req.slotDate.isNotEmpty ? req.slotDate : DateFormat('yyyy-MM-dd').format(req.slotStart)}',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

                // 2. Clinic & Doctor Details
                _buildCard(
                  title: 'Clinic & Doctor Details',
                  icon: Icons.local_hospital_rounded,
                  children: [
                    _buildRow('Clinic Name', req.clinicName),
                    _buildRow('Doctor Name', req.dentistName),
                    _buildRow('Mobile (Tap to Call)', req.mobile),
                    _buildRow('Address', req.address.fullAddress),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      onPressed: () async {
                        final lat = req.address.lat;
                        final lng = req.address.lng;
                        final fullAddress = req.address.fullAddress.trim();
                        String url;
                        if (lat > 0 && lng > 0) {
                          url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                        } else if (fullAddress.isNotEmpty) {
                          url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fullAddress)}';
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No location coordinates or address available for this ticket.')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final uri = Uri.parse(url);
                          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                          if (!launched && mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Could not open map: $url')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to launch Google Maps: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('Open in Google Maps'),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. Equipment & Schedule
                _buildCard(
                  title: 'Breakdown & Schedule',
                  icon: Icons.build_rounded,
                  children: [
                    _buildRow('Category', req.issueLabel.isNotEmpty ? req.issueLabel : req.issueCode),
                    _buildRow('Problem Description', req.issueDescription),
                    _buildRow('Created At', dateFormat.format(req.createdAt)),
                    if (req.assignedTechnicianName != null && req.assignedTechnicianName!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildRow('Assigned Tech', req.assignedTechnicianName!),
                      if (req.assignedTechnicianPhone != null && req.assignedTechnicianPhone!.isNotEmpty)
                        _buildRow('Tech Phone', req.assignedTechnicianPhone!),
                    ],
                    if (req.isCompleted) ...[
                      const Divider(height: 16),
                      _buildRow('Amount Paid', '₹${req.amountPaid?.toInt() ?? 0}'),
                      _buildRow('Completed By', req.completedBy == 'admin' ? 'Admin Override' : 'Doctor'),
                    ],
                    if (req.isCancelled) ...[
                      const Divider(height: 16),
                      _buildRow('Cancellation Reason', req.reasonText ?? 'Cancelled'),
                      _buildRow('Cancelled By', req.cancelledBy == 'admin' ? 'Admin' : 'Doctor'),
                    ],
                  ],
                ),

                const SizedBox(height: 14),

                // 4. Dispatch Actions
                _buildCard(
                  title: 'Dispatch Actions',
                  icon: Icons.alt_route_rounded,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (TechnicianRequestModel.canAdminAssign(req.status)) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                            onPressed: () => _handleAssignTechnician(req),
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text(hasTechnician ? 'Reassign Tech' : 'Assign Technician'),
                          ),
                        ],
                        if (TechnicianRequestModel.canAdminCloseOnBehalf(req.status)) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
                            onPressed: () => _handleCloseOnBehalf(req),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Close on Behalf'),
                          ),
                        ],
                        if (TechnicianRequestModel.canAdminCancel(req.status)) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
                            onPressed: () => _handleAdminCancel(req, config),
                            icon: const Icon(Icons.block_rounded, size: 16),
                            label: const Text('Cancel / Deny'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 6. Audit Event History
                _buildCard(
                  title: 'Audit Event History',
                  icon: Icons.history_rounded,
                  children: [
                    eventsAsync.when(
                      loading: () => const SizedBox(height: 30, child: Center(child: CircularProgressIndicator())),
                      error: (err, _) => Text('Error: $err', style: const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                      data: (events) {
                        if (events.isEmpty) {
                          return const Text('No events recorded yet.', style: TextStyle(color: AppTheme.textHint, fontSize: 12));
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
                                              '${AppTheme.getStatusLabel(event.status)} (by ${event.by})',
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

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildCard({
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryDark),
              ),
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
            width: 130,
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

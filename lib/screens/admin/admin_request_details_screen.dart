import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/booking_config_model.dart';
import '../../models/technician_model.dart';
import '../../models/technician_request_model.dart';
import '../../providers/auth_providers.dart';
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
  final _newNoteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void dispose() {
    _newNoteController.dispose();
    super.dispose();
  }

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
                decoration: const InputDecoration(labelText: 'Phone Number (10 digits) *', hintText: '9876543210'),
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

  Future<void> _handleSetInProgress(TechnicianRequestModel req) async {
    try {
      await ref.read(requestRepositoryProvider).setInProgress(requestId: req.id);
      ref.invalidate(requestDetailProvider(req.id));
      ref.invalidate(adminRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.successColor,
            content: Text('Ticket marked In Progress.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _handleCloseOnBehalf(TechnicianRequestModel req) async {
    final amountController = TextEditingController(text: '0');
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
                decoration: const InputDecoration(prefixText: '₹ ', hintText: '0 to 100000'),
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
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
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

  Future<void> _handleAddNote() async {
    final note = _newNoteController.text.trim();
    if (note.isEmpty) return;

    final user = ref.read(currentUserProfileProvider).value;
    final authorEmail = user?.email ?? 'operations@riodent.com';

    setState(() => _isAddingNote = true);
    try {
      await ref.read(requestRepositoryProvider).addInternalNote(
        requestId: widget.requestId,
        note: note,
        authorEmail: authorEmail,
      );
      _newNoteController.clear();
      ref.invalidate(internalNotesProvider(widget.requestId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAddingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeTechniciansProvider);
    final reqAsync = ref.watch(requestDetailProvider(widget.requestId));
    final eventsAsync = ref.watch(requestEventsProvider(widget.requestId));
    final notesAsync = ref.watch(internalNotesProvider(widget.requestId));
    final config = ref.watch(bookingConfigProvider).value ?? BookingConfigModel.defaultConfig();
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Ticket Review'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: reqAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (req) {
          if (req == null) {
            return const Center(child: Text('Ticket not found'));
          }

          final statusColor = AppTheme.getStatusColor(req.status);
          final hasTechnician = req.assignedTechnicianId != null && req.assignedTechnicianId!.isNotEmpty;

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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.primaryDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Slot: ${req.slotDate.isNotEmpty ? req.slotDate : DateFormat('yyyy-MM-dd').format(req.slotStart)} (${DateFormat('h:mm a').format(req.slotStart)})',
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
                          AppTheme.getStatusLabel(req.status),
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

                // Clinic & Doctor Contact Card
                _buildCard(
                  title: 'Clinic & Doctor Details',
                  icon: Icons.local_hospital_rounded,
                  children: [
                    _buildRow('Clinic Name', req.clinicName),
                    _buildRow('Doctor Name', req.dentistName),
                    _buildRow('Mobile (Tap to Call)', req.mobile),
                    _buildRow('Address', req.address.fullAddress),
                    const SizedBox(height: 8),
                    // Open in Google Maps button (free plain url)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      onPressed: () {
                        final lat = req.address.lat;
                        final lng = req.address.lng;
                        final query = (lat > 0 && lng > 0)
                            ? '$lat,$lng'
                            : Uri.encodeComponent(req.address.fullAddress);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Maps Link: https://www.google.com/maps/search/?api=1&query=$query')),
                        );
                      },
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('Open in Google Maps'),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Equipment & Issue Card
                _buildCard(
                  title: 'Breakdown & Schedule',
                  icon: Icons.build_rounded,
                  children: [
                    _buildRow('Category', req.issueLabel),
                    _buildRow('Problem Description', req.issueDescription),
                    _buildRow('Created At', dateFormat.format(req.createdAt)),
                    if (req.assignedTechnicianName != null) ...[
                      const Divider(height: 16),
                      _buildRow('Assigned Tech', req.assignedTechnicianName!),
                      if (req.assignedTechnicianPhone != null)
                        _buildRow('Tech Phone', req.assignedTechnicianPhone!),
                    ],
                    if (req.isCompleted) ...[
                      const Divider(height: 16),
                      _buildRow('Amount Paid (Reported)', '₹${req.amountPaid?.toInt() ?? 0}'),
                      _buildRow('Completed By', req.completedBy == 'admin' ? 'Admin Override' : 'Doctor'),
                    ],
                    if (req.isCancelled) ...[
                      const Divider(height: 16),
                      _buildRow('Cancellation Reason', req.reasonText ?? 'Cancelled'),
                      _buildRow('Cancelled By', req.cancelledBy == 'admin' ? 'RioDent Operations' : 'Doctor'),
                    ],
                  ],
                ),

                const SizedBox(height: 14),

                // Administrative Dispatch Actions
                _buildCard(
                  title: 'Dispatch Actions',
                  icon: Icons.alt_route_rounded,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Assign / Reassign
                        if (TechnicianRequestModel.canAdminAssign(req.status)) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                            onPressed: () => _handleAssignTechnician(req),
                            icon: const Icon(Icons.person_add_rounded, size: 16),
                            label: Text(hasTechnician ? 'Reassign Tech' : 'Assign Technician'),
                          ),
                        ],

                        // Set In Progress (disabled until assigned)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusInProgress),
                          onPressed: TechnicianRequestModel.canAdminSetInProgress(
                            status: req.status,
                            hasTechnician: hasTechnician,
                          )
                              ? () => _handleSetInProgress(req)
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('Set In Progress'),
                        ),

                        // Close on behalf
                        if (TechnicianRequestModel.canAdminCloseOnBehalf(req.status)) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor, foregroundColor: Colors.white),
                            onPressed: () => _handleCloseOnBehalf(req),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Close on Behalf'),
                          ),
                        ],

                        // Cancel / Deny
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

                // Internal Notes Subcollection (Admin only)
                _buildCard(
                  title: 'Internal Admin Notes (Private)',
                  icon: Icons.note_alt_rounded,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newNoteController,
                            decoration: const InputDecoration(
                              hintText: 'Add private dispatch note...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isAddingNote ? null : _handleAddNote,
                          child: _isAddingNote
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    notesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                      data: (notes) {
                        if (notes.isEmpty) {
                          return const Text('No internal notes recorded yet.', style: TextStyle(color: AppTheme.textHint, fontSize: 12));
                        }
                        return Column(
                          children: notes.map((n) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.comment_outlined, size: 16, color: AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(n['note'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text(
                                          'By ${n['author'] ?? 'Admin'}',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
                                        ),
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

                const SizedBox(height: 14),

                // Status Audit Events Timeline
                _buildCard(
                  title: 'Audit Event History',
                  icon: Icons.history_rounded,
                  children: [
                    eventsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                      data: (events) {
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

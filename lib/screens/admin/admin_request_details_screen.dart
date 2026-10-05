import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/request_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Screen for administrative review of a single request, technician assignment, and status transitions.
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
  final _notesController = TextEditingController();
  bool _isSavingNotes = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    final repo = ref.read(requestRepositoryProvider);
    try {
      await repo.updateStatus(
        requestId: widget.requestId,
        newStatus: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status changed to ${AppTheme.getStatusLabel(newStatus)}')),
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

  Future<void> _saveAdminNotes() async {
    setState(() => _isSavingNotes = true);
    final repo = ref.read(requestRepositoryProvider);
    try {
      await repo.updateAdminNotes(
        requestId: widget.requestId,
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin notes saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save notes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reqAsync = ref.watch(requestDetailProvider(widget.requestId));
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Request Management'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: reqAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (req) {
          if (req == null) {
            return const Center(child: Text('Request not found'));
          }

          if (_notesController.text.isEmpty && req.adminNotes != null) {
            _notesController.text = req.adminNotes!;
          }

          final statusColor = AppTheme.getStatusColor(req.status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Status Card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Current Status', style: theme.textTheme.labelMedium),
                            const SizedBox(height: 4),
                            Text(
                              AppTheme.getStatusLabel(req.status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        if (req.status == AppConstants.statusNew)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 42)),
                            onPressed: () => context.push('/admin/assign/${req.id}'),
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: const Text('Assign Tech'),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Dentist & Clinic Card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dentist & Clinic', style: theme.textTheme.titleMedium),
                        const Divider(height: 20),
                        Text(req.clinicName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(req.clinicAddress, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        Text('Doctor: ${req.dentistName}', style: theme.textTheme.bodyMedium),
                        Text('Phone: ${req.dentistPhone}', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text('Created: ${dateFormat.format(req.createdAt)}', style: theme.textTheme.bodySmall),
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
                        Text('Issue Information', style: theme.textTheme.titleMedium),
                        const Divider(height: 20),
                        Text('Category: ${req.issueType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Description:', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 2),
                        Text(req.issueDescription, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Assigned Technician info
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Assigned Technician', style: theme.textTheme.titleMedium),
                            TextButton(
                              onPressed: () => context.push('/admin/assign/${req.id}'),
                              child: Text(req.assignedTechnicianName == null ? 'Assign' : 'Reassign'),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Text(
                          req.assignedTechnicianName ?? 'No technician assigned yet',
                          style: TextStyle(
                            color: req.assignedTechnicianName == null ? AppTheme.textHint : AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Status Management Controls
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Progress Status', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (req.status != AppConstants.statusInProgress)
                              OutlinedButton(
                                onPressed: () => _updateStatus(AppConstants.statusInProgress),
                                child: const Text('Set In Progress'),
                              ),
                            if (req.status != AppConstants.statusCompleted)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  minimumSize: const Size(140, 44),
                                ),
                                onPressed: () => _updateStatus(AppConstants.statusCompleted),
                                child: const Text('Mark Completed'),
                              ),
                            if (req.status != AppConstants.statusCancelled)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorColor),
                                onPressed: () => _updateStatus(AppConstants.statusCancelled),
                                child: const Text('Cancel Request'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Admin Internal Notes
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Internal Admin Notes', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Notes for internal dispatch reference...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
                            onPressed: _isSavingNotes ? null : _saveAdminNotes,
                            child: _isSavingNotes
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Save Notes'),
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
}

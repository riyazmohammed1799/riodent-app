import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/technician_request_model.dart';
import '../../providers/request_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Screen listing requests submitted by the logged-in doctor with filter chips and pagination.
/// Implements Section 3.7:
/// Filter chips: All, Pending, Assigned, In progress, Completed, Cancelled.
class MyRequestsScreen extends ConsumerStatefulWidget {
  final String? initialFilter;

  const MyRequestsScreen({super.key, this.initialFilter});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen> {
  late String _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter ?? 'ALL';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(dentistRequestsProvider);

    final filters = [
      {'key': 'ALL', 'label': 'All'},
      {'key': AppConstants.statusNew, 'label': 'Pending'},
      {'key': AppConstants.statusAssigned, 'label': 'Assigned'},
      {'key': AppConstants.statusInProgress, 'label': 'In Progress'},
      {'key': AppConstants.statusCompleted, 'label': 'Completed'},
      {'key': AppConstants.statusCancelled, 'label': 'Cancelled'},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Service Requests'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: 10),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final f = filters[index];
                    final isSelected = _activeFilter == f['key'];
                    return ChoiceChip(
                      label: Text(f['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _activeFilter = f['key']!);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1),

            // Requests List
            Expanded(
              child: requestsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to load requests: $err', textAlign: TextAlign.center),
                  ),
                ),
                data: (allRequests) {
                  // Filter list
                  List<TechnicianRequestModel> filteredList;
                  if (_activeFilter == 'ALL') {
                    filteredList = allRequests;
                  } else if (_activeFilter == 'ACTIVE') {
                    filteredList = allRequests.where((r) => r.isActive).toList();
                  } else {
                    filteredList = allRequests.where((r) => r.status == _activeFilter).toList();
                  }

                  if (filteredList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 54, color: AppTheme.textHint),
                            const SizedBox(height: 14),
                            Text(
                              'No ${_filterLabel(_activeFilter)} requests found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'When you submit an equipment repair, you can track technician dispatch and closure here.',
                              style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(dentistRequestsProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = filteredList[index];
                        return _buildRequestCard(context, req, theme);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, TechnicianRequestModel req, ThemeData theme) {
    final statusColor = AppTheme.getStatusColor(req.status);
    final statusLabel = AppTheme.getStatusLabel(req.status);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => context.push('/dentist/requests/${req.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    req.displayTicketId,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                req.issueLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                req.issueDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),

              // Visit slot
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Slot: ${req.slotDate.isNotEmpty ? req.slotDate : DateFormat('MMM dd').format(req.slotStart)} (${DateFormat('h:mm a').format(req.slotStart)})',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),

              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    req.assignedTechnicianName != null
                        ? 'Tech: ${req.assignedTechnicianName}'
                        : 'Awaiting dispatch',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: req.assignedTechnicianName != null ? AppTheme.primaryColor : AppTheme.textSecondary,
                    ),
                  ),
                  if (req.isCompleted && req.amountPaid != null) ...[
                    Text(
                      'Paid: ₹${req.amountPaid!.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor, fontSize: 13),
                    ),
                  ] else ...[
                    Text(
                      dateFormat.format(req.createdAt),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _filterLabel(String filterKey) {
    switch (filterKey) {
      case 'NEW':
        return 'Pending';
      case 'ASSIGNED':
        return 'Assigned';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return '';
    }
  }
}
